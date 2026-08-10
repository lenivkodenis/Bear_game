# BearMath staging

The manual `Build and deploy staging Web` workflow publishes only to the
isolated `staging-deploy` branch. It never writes to production `web-deploy`.

There is currently no confirmed public host for `staging-deploy`. To obtain a
staging URL, configure a separate Timeweb application, static host, or other
location that serves this branch, then pass that URL to the workflow's optional
`staging_url` input so it is visible in the run summary.

The workflow can compile `ENABLE_VISUAL_TEST_MODE=true`. Special visual-test
query parameters remain inert in the normal production build.
