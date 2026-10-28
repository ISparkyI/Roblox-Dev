# My Mining Golems — підключення Google Таблиці до гри

Таблиця зберігає **новини (Updates)**, **промокоди (Codes)** та **відгуки гравців (Feedback)**.
Гра (сервер Roblox) звертається до неї через Google Apps Script, опублікований як Web App.

Файли:
- `MyMiningGolems_Backend.xlsx` — таблиця з прикладами
- `Code.gs` — скрипт-бекенд
- `INSTRUCTIONS.md` — ця інструкція

---

## Крок 1. Завантажити таблицю в Google Drive

1. Відкрийте https://drive.google.com.
2. **Створити → Завантажити файл** (New → File upload) → оберіть `MyMiningGolems_Backend.xlsx`.
3. Двічі клацніть файл → вгорі **Відкрити за допомогою → Google Таблиці** (Open with → Google Sheets).
4. **Файл → Зберегти як Google Таблиці** (File → Save as Google Sheets).
   Далі працюйте **з новою копією** (без значка «XLSX» біля назви). Оригінальний .xlsx можна видалити.

## Крок 2. Додати скрипт

1. У Google Таблиці: **Розширення → Apps Script** (Extensions → Apps Script).
2. Видаліть увесь текст у файлі `Code.gs` редактора і вставте **повністю** вміст нашого `Code.gs`.
3. Натисніть 💾 **Зберегти** (Ctrl+S).

## Крок 3. Задати секретний ключ SECRET

1. У редакторі Apps Script зліва ⚙ **Налаштування проєкту** (Project Settings).
2. Внизу **Властивості скрипту → Додати властивість** (Script properties → Add script property):
   - Властивість (Property): `SECRET`
   - Значення (Value): довгий випадковий рядок, наприклад
     `KdyPcPw5KSH1GLi7AKlFraoD`
     (краще придумайте свій — 24+ латинських літер і цифр; або в таблиці меню **⛏ Golems → Згенерувати SECRET**).
3. **Зберегти властивості скрипту**.

> Без SECRET скрипт відповідає на всі запити `{"ok":false,"error":"auth"}`.

## Крок 4. Опублікувати як Web App

1. Вгорі праворуч **Розгорнути → Нове розгортання** (Deploy → New deployment).
2. ⚙ біля «Виберіть тип» → **Вебзастосунок** (Web app).
3. Налаштування:
   - Опис: `Golems API v1`
   - **Виконувати як (Execute as): Я (Me)**
   - **Хто має доступ (Who has access): Усі (Anyone)**
4. **Розгорнути**. Google попросить дозволи: **Надати доступ → оберіть свій акаунт → Додатково (Advanced) → Перейти до … (небезпечно) → Дозволити**. Це нормально — скрипт ваш.
5. Скопіюйте **URL вебзастосунку** (виглядає як `https://script.google.com/macros/s/AKfy.../exec`).

## Крок 5. Перевірити

Відкрийте у браузері (підставте свої значення):

```
https://script.google.com/macros/s/ВАШ_ID/exec?action=updates&key=ВАШ_SECRET
```

Має з'явитися `{"ok":true,"updates":[...]}`. Так само `?action=codes&key=...`.
З неправильним key — `{"ok":false,"error":"auth"}`.

## Крок 6. Одноразове налаштування таблиці

Поверніться в таблицю і оновіть сторінку (F5). З'явиться меню **⛏ Golems**:
- **Налаштувати таблицю (чекбокси, кольори)** — запустіть **1 раз**: колонки Active/Pinned стануть чекбоксами, з'являться списки Reward/Status, клітинки кольорів заллються своїм кольором, аркуш RedeemLog буде приховано.
  (Перший запуск теж попросить дозволи — погодьтеся.)

## Крок 7. Передати дані грі

Надішліть Claude **URL Web App** і **SECRET** — або вставте їх у конфіг гри в Roblox Studio (у ServerStorage; точне місце/назву модуля вкаже агент, що робить гру).
⚠ Ніде не публікуйте SECRET і не кладіть його в ReplicatedStorage / клієнтські скрипти.

## Крок 8. Roblox: дозволити HTTP

У Roblox Studio: **Home → Game Settings → Security → Allow HTTP Requests = ON** → Save. Без цього `HttpService` не працює.

---

## ⚠ Після будь-якої зміни скрипту

Зміни в `Code.gs` **не потрапляють** у вже опублікований URL автоматично:
**Розгорнути → Керувати розгортаннями → ✏ (Редагувати) → Версія: Нова версія → Розгорнути** (Deploy → Manage deployments → Edit → Version: New version → Deploy).
URL при цьому **залишається той самий**. (Не робіть «Нове розгортання» — тоді URL зміниться.)

### Оновлення скрипту (redeem/feedback через GET)

Нова версія `Code.gs` приймає активацію кодів і відгуки також через **GET**: у Roblox `PostAsync` на Apps Script давав помилку **HTTP 405**. Щоб її оновити:
1. **Розширення → Apps Script** → виділіть увесь старий код у `Code.gs` (Ctrl+A) → вставте новий `Code.gs` → 💾 Зберегти.
2. **Розгорнути → Керувати розгортаннями** (Deploy → Manage deployments) → **✏ олівець (Edit)** → **Версія: Нова версія** (Version: New version) → **Розгорнути** (Deploy).
3. URL **залишається той самий**, і SECRET не змінюється. Нічого не треба передавати в гру заново.

Зміни **в таблиці** (новини, коди) редеплою не потребують — гра побачить їх за ~30–60 с (кеш). Щоб одразу — **⛏ Golems → Очистити кеш API** (кеш також очищується автоматично при редагуванні).

---

## Як редагувати

### Updates (новини)
| Колонка | Що писати |
|---|---|
| ID | унікальний ID (u1, u2, …) — не змінюйте у вже опублікованих новинах |
| Active | ☑ = показувати в грі |
| Pinned | ☑ = закріпити вгорі |
| Date | дата `РРРР-ММ-ДД` |
| Version | `0.3` тощо |
| Title / Title Color | заголовок і його колір `#rrggbb` |
| Text / Text Color | текст і основний колір |
| Image | Roblox asset id (цифри) або порожньо |
| Note | нотатка для себе (у гру не йде) |

Порядок у грі: спочатку закріплені, далі новіші за датою.

**Розмітка в Text:**
- `[#ff5a5a]червоні слова[/]` — кольорові слова (тег `[#колір]` … `[/]`)
- `**жирний**` — жирний текст
- можна разом: `[#ffd24a]**золоте жирне**[/]`
- новий рядок у клітинці — **Ctrl+Enter**

Кольори — завжди `#` + 6 hex-символів: `#ff5a5a` червоний, `#5af078` зелений, `#7ad7ff` блакитний, `#ffd24a` золотий, `#b47aff` фіолетовий.
Неправильний колір підсвічується рожевим.

**Заливка клітинки власним кольором.** Умовне форматування Google Sheets не вміє брати колір із тексту клітинки, тому це робить скрипт: при редагуванні Title Color / Text Color (тригер `onEdit`) або через меню **⛏ Golems → Розфарбувати кольорові клітинки**. У прикладах з xlsx заливка вже стоїть.

### Codes (промокоди)
| Reward | Amount | Item |
|---|---|---|
| Diamonds / Tickets / Money | кількість | порожньо |
| Potion | кількість зілля | `Luck`, `Speed`, `Money` або `Strength` |
| Golem | кількість големів | id голема: `stone`, або з мутацією `stone@3` |

- **Expires** — останній день дії (`РРРР-ММ-ДД`), порожньо = безстроково.
- **Max Uses** — загальний ліміт активацій (0 = без ліміту). **Uses** скрипт рахує сам.
- Вимкнути код — зняти ☑ Active.
- Що гравець не використає код двічі — перевіряє сама гра.
- Журнал активацій — прихований аркуш **RedeemLog** (☰ «Усі аркуші» внизу зліва → RedeemLog).

### Feedback (відгуки)
Рядки додає гра (час, гравець, категорія Bug/Idea/Other, текст ≤1000 символів, карта, гроші, версія, пристрій, PlaceId, JobId).
Один гравець — не частіше 1 відгуку на 60 с.
**Status**: `New` (жовтий) → `Seen` → `Fixed` (зелений) / `Won't fix` (сірий). Колонка **Note** — для ваших нотаток.

### Важливо
- **Не перейменовуйте заголовки** в першому рядку (колонки переставляти можна).
- **Не перейменовуйте аркуші** Updates / Codes / Feedback / RedeemLog.

---

## Довідка по API (для гри)

| Запит | Відповідь |
|---|---|
| `GET ?action=updates&key=…` | `{ok:true, updates:[{id, version, date, title, titleColor, text, textColor, image, pinned}]}` |
| `GET ?action=codes&key=…` | `{ok:true, codes:[{code, reward, amount, item, expires, maxUses, uses, active}]}` |
| `POST {action:"redeem", key, code, userId, name}` | `{ok:true}` або `{ok:false, error:"notfound"/"inactive"/"expired"/"limit"}` |
| `POST {action:"feedback", key, userId, name, category, text, map, money, version, placeId, jobId, device}` | `{ok:true}` або `{ok:false, error:"rate"}` |

| `GET ?action=redeem&key=…&code=…&userId=…&name=…` | те саме, що POST redeem |
| `GET ?action=feedback&key=…&userId=…&name=…&category=…&text=…&map=…&money=…&version=…&placeId=…&jobId=…&device=…` | те саме, що POST feedback |
| `GET ?data=<URL-encoded JSON {action, key, …усі поля}>` | альтернатива: якщо є `data`, поля беруться з нього |

> Roblox: `PostAsync` не працює (Apps Script відповідає редиректом 302, Roblox повторює його як POST і отримує 405). Для redeem/feedback використовуйте `GetAsync` з параметрами в URL (`HttpService:UrlEncode`) або з `data=UrlEncode(JSONEncode(table))`.

Інші помилки: `auth`, `bad_json`, `unknown_action`, `busy`, `empty`, `server: …`.
Перевірка зв'язку: `GET ?action=ping&key=…`.
