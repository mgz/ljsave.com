LJSave.com состоит из трех частей:

### 1. Скрапер (парсер)
Нужен, чтобы скачать блог с livejournal.com вместе с раскрытыми комментариями.

Лежит в папке `/scraper/`.

Представляет собой ruby-скрипты, которые запускают браузер Chrome при помощи Selenium и скачивают посты с livejournal.com.

Во время парсинга из страниц [вырезаются](https://github.com/mgz/ljsave.com/blob/05e6bbba67f4aacd3a404c35b155c5aa1ce8205e/scraper/src/common/bot/post.rb#L93..L100) лишние скрипты, формы логина и т.д.

После этого при помощи wget [скачиваются](https://github.com/mgz/ljsave.com/blob/05e6bbba67f4aacd3a404c35b155c5aa1ce8205e/scraper/src/common/bot/user.rb#L65) все нужные для отображения файлы - картинки, стили и т.д.

Затем мы [строим файл json](https://github.com/mgz/ljsave.com/blob/05e6bbba67f4aacd3a404c35b155c5aa1ce8205e/scraper/src/common/bot/user.rb#L90), в котором перечислены скачанные нами посты и информация о них - название, дата, кол-во комментариев.

Теперь локальная копия блога ЖЖ готова. Чтобы ее отобразить, используется вторая часть:

### 2. Сайт на Ruby on Rails
Сайт берет локальные копии ЖЖ-постов из `/public/lj` и показывает посетителям.

Для удобства мы:
1. [Добавляем](https://github.com/mgz/ljsave.com/blob/b31a99e7ecf20d8a3ae8267a4ee4fff4ccbfc4f8/app/services/post.rb#L21) нужные нам скрипты, стили и мета-теги
1. [Добавляем](https://github.com/mgz/ljsave.com/blob/b31a99e7ecf20d8a3ae8267a4ee4fff4ccbfc4f8/app/services/post.rb#L26) navigation bar вверху страницы
1. [Заменяем](https://github.com/mgz/ljsave.com/blob/b31a99e7ecf20d8a3ae8267a4ee4fff4ccbfc4f8/app/services/post.rb#L37) некоторые ссылки на локальные

### 3. Скачанные данные
Данные из `/public/lj/` мы храним в отдельном репозитории https://github.com/mgz/ljsave.com-data

Их нужно положить в папку `/public/lj/`

```sh
USE_CACHE=1 DEBUG_LOG=0 brake scraper:download username=USER
```
