# Web-деплой Bear Game

Production-публикация устроена так:

`main` → GitHub Actions → `flutter build web --release` → `web-deploy` → Timeweb Cloud.

При каждом push в `main` workflow `.github/workflows/deploy-web.yml` устанавливает Flutter 3.44.9, получает зависимости, запускает анализ и тесты, собирает Web-приложение и проверяет, что в результате нет Git LFS pointer-файлов. Только после успешных проверок содержимое `build/web` публикуется непосредственно в корень orphan-ветки `web-deploy`.

Для Timeweb App Platform нужно будет выбрать репозиторий `lenivkodenis/Bear_game`, ветку `web-deploy` и раздачу статических файлов из корня ветки. Сборочная команда на стороне Timeweb не нужна. Сам Timeweb и домен этим workflow не настраиваются.
