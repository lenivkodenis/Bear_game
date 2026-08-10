import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, rm, stat, writeFile } from 'node:fs/promises';
import { extname, join, normalize, resolve, sep } from 'node:path';
import process from 'node:process';
import jpeg from 'jpeg-js';
import pixelmatch from 'pixelmatch';
import { chromium } from 'playwright';
import { PNG } from 'pngjs';

const repositoryRoot = resolve(import.meta.dirname, '../..');
const webRoot = join(repositoryRoot, 'build/web');
const baselineRoot = join(repositoryRoot, 'test/visual_baselines');
const artifactRoot = join(repositoryRoot, 'artifacts/visual-diffs');
const updateBaselines = process.env.UPDATE_VISUAL_BASELINES === '1';
const caseFilter = process.env.VISUAL_CASE_FILTER;
const debugVisual = process.env.DEBUG_VISUAL === '1';
const maxDiffPixelRatio = 0.003;
const pixelThreshold = 0.12;

const viewports = [
  { name: '1280x720', width: 1280, height: 720 },
  { name: '1440x900', width: 1440, height: 900 },
  { name: '1920x1080', width: 1920, height: 1080 },
  { name: '2048x1000', width: 2048, height: 1000 },
];
const levelOneCheckpoints = [
  'start',
  'beforeFirstObstacle',
  'onFirstObstacle',
  'beforeSecondObstacle',
  'mentor',
];

const screenshotCases = viewports.flatMap((viewport) =>
  levelOneCheckpoints.map((checkpoint) => ({
    name: `level-01-${checkpoint}-${viewport.name}`,
    viewport,
    route: gameRoute(1, checkpoint),
    ready: 'scene',
  })),
);

const defaultViewport = viewports[0];
screenshotCases.push(
  ...[3, 5, 9].map((levelId) => ({
    name: `level-${String(levelId).padStart(2, '0')}-start-${defaultViewport.name}`,
    viewport: defaultViewport,
    route: gameRoute(levelId, 'start'),
    ready: 'scene',
  })),
  {
    name: `main-menu-${defaultViewport.name}`,
    viewport: defaultViewport,
    route: '/?visualTest=1',
    ready: 'app',
  },
  {
    name: `location-map-${defaultViewport.name}`,
    viewport: defaultViewport,
    route: '/?visualTest=1&checkpoint=map',
    ready: 'app',
  },
  {
    name: `level-01-task-dialog-${defaultViewport.name}`,
    viewport: defaultViewport,
    route: gameRoute(1, 'taskDialog'),
    ready: 'scene',
    action: 'openFirstTask',
  },
  {
    name: `level-01-collision-${defaultViewport.name}`,
    viewport: defaultViewport,
    route: gameRoute(1, 'collision'),
    ready: 'scene',
  },
);

function gameRoute(levelId, checkpoint) {
  return `/?visualTest=1&levelId=${levelId}&checkpoint=${checkpoint}`;
}

function mimeType(path) {
  return {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.jpeg': 'image/jpeg',
    '.jpg': 'image/jpeg',
    '.js': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.mjs': 'text/javascript; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.wasm': 'application/wasm',
  }[extname(path).toLowerCase()] ?? 'application/octet-stream';
}

async function createStaticServer() {
  const server = createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
      const decodedPath = decodeURIComponent(requestUrl.pathname);
      const candidate = normalize(join(webRoot, decodedPath));
      if (candidate !== webRoot && !candidate.startsWith(`${webRoot}${sep}`)) {
        response.writeHead(403).end('Forbidden');
        return;
      }

      let filePath = candidate;
      try {
        const fileStat = await stat(filePath);
        if (fileStat.isDirectory()) filePath = join(filePath, 'index.html');
      } catch {
        filePath = join(webRoot, 'index.html');
      }

      const body = await readFile(filePath);
      response.writeHead(200, {
        'Cache-Control': filePath.endsWith('index.html')
          ? 'no-store'
          : 'public, max-age=31536000, immutable',
        'Content-Type': mimeType(filePath),
      });
      response.end(body);
    } catch (error) {
      response.writeHead(500).end(String(error));
    }
  });

  await new Promise((resolvePromise, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolvePromise);
  });
  const address = server.address();
  assert(address && typeof address !== 'string');
  return { server, origin: `http://127.0.0.1:${address.port}` };
}

async function waitForStableFrame(page, ready) {
  try {
    await page.waitForSelector(`body[data-bear-ready="${ready}"]`, {
      state: 'attached',
      timeout: 45_000,
    });
  } catch (error) {
    const bodyState = await page.locator('body').evaluate((body) => ({
      ready: body.getAttribute('data-bear-ready'),
      visualTest: body.getAttribute('data-bear-visual-test'),
      text: body.textContent?.slice(0, 300),
    }));
    await mkdir(artifactRoot, { recursive: true });
    await page.screenshot({
      path: join(artifactRoot, 'readiness-timeout.png'),
      type: 'png',
    });
    throw new Error(
      `Timed out at ${page.url()} waiting for ${ready}; body=${JSON.stringify(bodyState)}; ${error}`,
    );
  }
  await page.waitForLoadState('networkidle');
  await page.evaluate(async () => {
    if (document.fonts) await document.fonts.ready;
    await new Promise((resolvePromise) =>
      requestAnimationFrame(() => requestAnimationFrame(resolvePromise)),
    );
  });
  await page.waitForTimeout(300);
}

async function takeScreenshot(page) {
  return page.screenshot({
    type: 'jpeg',
    quality: 90,
    animations: 'disabled',
    caret: 'hide',
    fullPage: false,
  });
}

async function compareScreenshot(name, actualBuffer) {
  const baselinePath = join(baselineRoot, `${name}.jpg`);
  if (updateBaselines) {
    await mkdir(baselineRoot, { recursive: true });
    await writeFile(baselinePath, actualBuffer);
    process.stdout.write(`BASELINE ${name}\n`);
    return;
  }

  let expectedBuffer;
  try {
    expectedBuffer = await readFile(baselinePath);
  } catch {
    throw new Error(
      `Missing baseline ${baselinePath}. Run npm run baseline:visual after owner review.`,
    );
  }

  const expected = jpeg.decode(expectedBuffer, { useTArray: true });
  const actual = jpeg.decode(actualBuffer, { useTArray: true });
  assert.equal(actual.width, expected.width, `${name}: screenshot width changed`);
  assert.equal(actual.height, expected.height, `${name}: screenshot height changed`);

  const diff = new PNG({ width: actual.width, height: actual.height });
  const differingPixels = pixelmatch(
    expected.data,
    actual.data,
    diff.data,
    actual.width,
    actual.height,
    { threshold: pixelThreshold, includeAA: false },
  );
  const ratio = differingPixels / (actual.width * actual.height);
  if (ratio > maxDiffPixelRatio) {
    await mkdir(artifactRoot, { recursive: true });
    await Promise.all([
      writeFile(join(artifactRoot, `${name}-expected.jpg`), expectedBuffer),
      writeFile(join(artifactRoot, `${name}-actual.jpg`), actualBuffer),
      writeFile(join(artifactRoot, `${name}-diff.png`), PNG.sync.write(diff)),
    ]);
    throw new Error(
      `${name}: ${(ratio * 100).toFixed(3)}% pixels differ; limit is ${(maxDiffPixelRatio * 100).toFixed(3)}%`,
    );
  }
  process.stdout.write(`PASS ${name} (${(ratio * 100).toFixed(3)}% diff)\n`);
}

async function captureCase(context, origin, testCase) {
  const page = await context.newPage();
  await page.setViewportSize({
    width: testCase.viewport.width,
    height: testCase.viewport.height,
  });
  page.on('console', (message) => {
    if (
      debugVisual ||
      message.type() === 'error' ||
      message.type() === 'warning'
    ) {
      process.stderr.write(`BROWSER ${message.type()}: ${message.text()}\n`);
    }
  });
  page.on('pageerror', (error) => {
    process.stderr.write(`BROWSER pageerror: ${error.stack ?? error}\n`);
  });
  await page.goto(`${origin}${testCase.route}`, { waitUntil: 'domcontentloaded' });
  await waitForStableFrame(page, testCase.ready);
  if (testCase.action === 'openFirstTask') {
    await page.mouse.click(
      testCase.viewport.width / 2,
      testCase.viewport.height * 0.63,
    );
    await page.waitForTimeout(300);
  }
  await compareScreenshot(testCase.name, await takeScreenshot(page));
  await page.close();
}

async function runResizeRoundTrip(context, origin) {
  const page = await context.newPage();
  await page.setViewportSize({ width: 1280, height: 720 });
  await page.goto(`${origin}${gameRoute(1, 'beforeFirstObstacle')}`, {
    waitUntil: 'domcontentloaded',
  });
  await waitForStableFrame(page, 'scene');

  const readState = () =>
    page.locator('body').evaluate((body) => ({
      level: body.getAttribute('data-bear-level'),
      checkpoint: body.getAttribute('data-bear-checkpoint'),
      score: body.getAttribute('data-bear-score'),
    }));
  const initialState = await readState();
  assert.deepEqual(initialState, {
    level: '1',
    checkpoint: 'beforeFirstObstacle',
    score: '0',
  });

  await page.setViewportSize({ width: 1920, height: 1080 });
  await waitForStableFrame(page, 'scene');
  assert.deepEqual(await readState(), initialState, 'state changed at 1920x1080');

  await page.setViewportSize({ width: 1280, height: 720 });
  await waitForStableFrame(page, 'scene');
  assert.deepEqual(await readState(), initialState, 'state changed after resize round trip');

  await compareScreenshot(
    'level-01-resize-round-trip-1280x720',
    await takeScreenshot(page),
  );
  await page.close();
}

async function main() {
  await stat(join(webRoot, 'index.html'));
  await rm(artifactRoot, { recursive: true, force: true });
  const { server, origin } = await createStaticServer();
  const browser = await chromium.launch({
    headless: true,
    args: ['--font-render-hinting=none'],
  });
  const browserVersion = browser.version();
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 1,
    locale: 'ru-RU',
    timezoneId: 'Europe/Moscow',
    reducedMotion: 'reduce',
  });

  const failures = [];
  try {
    const selectedCases = caseFilter
      ? screenshotCases.filter((testCase) => testCase.name.includes(caseFilter))
      : screenshotCases;
    if (
      caseFilter &&
      selectedCases.length === 0 &&
      !'resize-round-trip'.includes(caseFilter)
    ) {
      throw new Error(`No screenshot case matches VISUAL_CASE_FILTER=${caseFilter}`);
    }
    for (const testCase of selectedCases) {
      try {
        await captureCase(context, origin, testCase);
      } catch (error) {
        failures.push(`${testCase.name}: ${error.stack ?? error}`);
      }
    }
    if (!caseFilter || 'resize-round-trip'.includes(caseFilter)) {
      try {
        await runResizeRoundTrip(context, origin);
      } catch (error) {
        failures.push(`resize-round-trip: ${error.stack ?? error}`);
      }
    }
  } finally {
    await context.close();
    await browser.close();
    await new Promise((resolvePromise, reject) =>
      server.close((error) => (error ? reject(error) : resolvePromise())),
    );
  }

  if (failures.length > 0) {
    throw new Error(`Visual regression failures:\n\n${failures.join('\n\n')}`);
  }
  process.stdout.write(
    `${updateBaselines ? 'Updated' : 'Verified'} ${caseFilter ? 'filtered' : screenshotCases.length + 1} screenshots with Chromium ${browserVersion}.\n`,
  );
}

await main();
