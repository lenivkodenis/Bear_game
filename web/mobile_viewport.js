(function () {
  'use strict';

  const root = document.documentElement;
  const host = document.getElementById('bearmath-host');
  const viewport = window.visualViewport;
  const debugEnabled = new URL(window.location.href).searchParams.get('debugViewport') === '1';
  const stableDelayMs = 260;
  let stableTimer = 0;
  let rafId = 0;
  let previousSample = '';
  let equalFrameCount = 0;
  let revision = 0;
  let latestReason = 'bootstrap';
  let debugElement = null;

  function snapshot() {
    const width = Math.max(1, viewport ? viewport.width : window.innerWidth);
    const height = Math.max(1, viewport ? viewport.height : window.innerHeight);
    const left = viewport ? viewport.offsetLeft : 0;
    const top = viewport ? viewport.offsetTop : 0;
    return {
      width,
      height,
      left,
      top,
      scale: viewport ? viewport.scale : 1,
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      dpr: window.devicePixelRatio || 1,
      orientation: screen.orientation ? screen.orientation.type : '',
      fullscreen: Boolean(document.fullscreenElement || document.webkitFullscreenElement),
      standalone: window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true,
      stable: equalFrameCount >= 2,
      revision,
      reason: latestReason,
    };
  }

  function sampleKey(value) {
    return [value.width, value.height, value.left, value.top, value.scale, value.dpr]
      .map((number) => Number(number).toFixed(2))
      .join('|');
  }

  function apply(value) {
    root.style.setProperty('--bearmath-vv-left', `${value.left}px`);
    root.style.setProperty('--bearmath-vv-top', `${value.top}px`);
    root.style.setProperty('--bearmath-vv-width', `${value.width}px`);
    root.style.setProperty('--bearmath-vv-height', `${value.height}px`);
    window.bearMathViewport = value;
    renderDebug(value);
  }

  function renderDebug(value) {
    if (!debugEnabled) return;
    if (!debugElement) {
      debugElement = document.createElement('pre');
      debugElement.id = 'bearmath-viewport-debug';
      document.body.appendChild(debugElement);
    }
    const hostRect = host.getBoundingClientRect();
    debugElement.textContent =
      `JS ${value.stable ? 'stable' : 'resizing'} #${value.revision} ${value.reason}\n` +
      `visual ${value.width.toFixed(1)}×${value.height.toFixed(1)} @ ${value.left.toFixed(1)},${value.top.toFixed(1)} s=${value.scale.toFixed(2)}\n` +
      `inner ${value.innerWidth}×${value.innerHeight} dpr=${value.dpr.toFixed(2)}\n` +
      `host ${hostRect.width.toFixed(1)}×${hostRect.height.toFixed(1)} @ ${hostRect.left.toFixed(1)},${hostRect.top.toFixed(1)}\n` +
      `orientation ${value.orientation || 'unknown'} fullscreen=${value.fullscreen} standalone=${value.standalone}`;
  }

  function announceStable(value) {
    const detail = { ...value, stable: true };
    window.bearMathViewport = detail;
    renderDebug(detail);
    window.dispatchEvent(new CustomEvent('bearmath:viewport-stable', { detail }));
    if (debugEnabled) console.info('[BearMath viewport] stable', detail);
  }

  function runFrames() {
    const value = snapshot();
    const key = sampleKey(value);
    equalFrameCount = key === previousSample ? equalFrameCount + 1 : 1;
    previousSample = key;
    apply({ ...value, stable: equalFrameCount >= 2 });

    if (equalFrameCount < 2) {
      rafId = requestAnimationFrame(runFrames);
      return;
    }

    clearTimeout(stableTimer);
    stableTimer = window.setTimeout(() => {
      const trailing = snapshot();
      if (sampleKey(trailing) !== previousSample) {
        schedule('trailing-change');
        return;
      }
      announceStable(trailing);
    }, stableDelayMs);
  }

  function schedule(reason) {
    latestReason = reason;
    revision += 1;
    equalFrameCount = 0;
    previousSample = '';
    clearTimeout(stableTimer);
    cancelAnimationFrame(rafId);
    if (debugEnabled) console.info('[BearMath viewport] resize', reason, snapshot());
    window.dispatchEvent(new CustomEvent('bearmath:viewport-resizing', { detail: snapshot() }));
    rafId = requestAnimationFrame(runFrames);
  }

  function add(target, eventName) {
    if (target) target.addEventListener(eventName, () => schedule(eventName), { passive: true });
  }

  ['resize', 'orientationchange', 'fullscreenchange', 'pageshow'].forEach((name) => add(window, name));
  ['focus', 'blur'].forEach((name) => add(window, name));
  add(document, 'fullscreenchange');
  add(document, 'webkitfullscreenchange');
  add(document, 'visibilitychange');
  add(viewport, 'resize');
  add(viewport, 'scroll');
  if ('ResizeObserver' in window) {
    new ResizeObserver(() => {
      if (host.clientWidth !== Math.round((window.bearMathViewport || {}).width || 0) ||
          host.clientHeight !== Math.round((window.bearMathViewport || {}).height || 0)) {
        schedule('host-resize-observer');
      }
    }).observe(host);
  }

  async function requestImmersive(lockLandscape) {
    let fullscreen = false;
    try {
      const target = document.documentElement;
      const request = target.requestFullscreen || target.webkitRequestFullscreen;
      if (request && !document.fullscreenElement && !document.webkitFullscreenElement) {
        await request.call(target);
      }
      fullscreen = Boolean(document.fullscreenElement || document.webkitFullscreenElement);
    } catch (error) {
      if (debugEnabled) console.info('[BearMath display] fullscreen unavailable', error);
    }

    if (lockLandscape && screen.orientation && screen.orientation.lock) {
      try {
        await screen.orientation.lock('landscape');
      } catch (error) {
        if (debugEnabled) console.info('[BearMath display] orientation lock unavailable', error);
      }
    }
    schedule('immersive-request');
    return fullscreen;
  }

  window.bearMathDisplay = {
    requestImmersive,
    metricsJson: () => JSON.stringify(window.bearMathViewport || snapshot()),
    isMobile: () => window.matchMedia('(pointer: coarse)').matches,
    isStandalone: () => window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true,
    fullscreenSupported: () => Boolean(document.documentElement.requestFullscreen || document.documentElement.webkitRequestFullscreen),
  };

  // The previous release removed every Flutter cache on every visit. Perform
  // that cleanup at most once, then let Flutter's normal versioned lifecycle
  // own the service worker and caches again.
  const migrationKey = 'bearmath-cache-migration-v3';
  try {
    if (localStorage.getItem(migrationKey) !== 'complete') {
      localStorage.setItem(migrationKey, 'started');
      Promise.resolve().then(async () => {
        if ('serviceWorker' in navigator) {
          const registrations = await navigator.serviceWorker.getRegistrations();
          await Promise.all(registrations.map((registration) => registration.unregister()));
        }
        if ('caches' in window) {
          const names = await caches.keys();
          await Promise.all(names.filter((name) => name.startsWith('flutter-')).map((name) => caches.delete(name)));
        }
        localStorage.setItem(migrationKey, 'complete');
      }).catch((error) => {
          console.warn('BearMath one-time cache migration was not completed.', error);
        });
    }
  } catch (error) {
    console.warn('BearMath cache migration storage is unavailable.', error);
  }

  schedule('bootstrap');
})();
