#  (3x-ui fork) روی Railway با یک پورت واحد

این ریپازیتوری، پنل Heimdall (نسخه‌ی بهبودیافته‌ی 3x-ui از sh7CBAC) را به همراه یک nginx reverse proxy اجرا می‌کند که پنل، ساب‌اسکریپشن و اینباند VLESS/WebSocket را از طریق **یک پورت واحد** (همان پورتی که Railway اختصاص می‌دهد) در دسترس می‌گذارد — دقیقاً همون معماری که برای x4gKing/3x-ui-Upgrade ساختیم و تست شد.

## درباره‌ی دیتابیس

Heimdall به‌صورت پیش‌فرض از **SQLite** استفاده می‌کند (نیازی به Postgres نیست، مگر بخواهید تعداد کاربر خیلی بالایی داشته باشید). این نسخه با همان تنظیم پیش‌فرض ساده (SQLite) پیکربندی شده.

## مراحل دیپلوی

### ۱. ریپازیتوری بسازید
یک ریپازیتوری جدید در گیت‌هاب بسازید و این سه فایل را در ریشه‌ی آن قرار دهید:
- `Dockerfile`
- `nginx.conf.template`
- `start.sh`

### ۲. در Railway
1. **New Project → Deploy from GitHub repo** و همین ریپازیتوری را انتخاب کنید
2. Railway به‌طور خودکار `Dockerfile` را تشخیص و بیلد می‌کند (دانلود آخرین نسخه‌ی Heimdall از گیت‌هاب به‌صورت خودکار در زمان Build انجام می‌شود)
3. بعد از اتمام دیپلوی، به **Settings → Networking** بروید و **Generate Domain** بزنید
4. مطمئن شوید **Target Port روی 3000** تنظیم شده (چون nginx دقیقاً روی همین پورت گوش می‌دهد)

### ۳. اولین ورود به پنل
```
https://دامنه‌شما.up.railway.app/managepanel/
```
یوزرنیم/پسورد پیش‌فرض `admin`/`admin` را وارد کنید و بلافاصله از تنظیمات پنل تغییرش دهید.

### ۴. ساخت Inbound

| فیلد | مقدار |
|---|---|
| Protocol | VLESS |
| **Listen Port** | **`8080`** (این عدد ثابت است) |
| Listen IP | خالی یا `0.0.0.0` |
| Network | ws |
| Security | none |
| Path | هر مسیر دلخواه، مثلاً `/cdn` |

### ۵. ساخت لینک کلاینت

```
vless://UUID@دامنه‌شما.up.railway.app:443?encryption=none&security=tls&sni=دامنه‌شما.up.railway.app&fp=chrome&type=ws&host=دامنه‌شما.up.railway.app&path=%2Fcdn#MyConfig
```

### ۶. لینک ساب‌اسکریپشن

مسیر ساب به‌صورت خودکار زیر همین دامنه در دسترس است:
```
https://دامنه‌شما.up.railway.app/sub/USER_SUB_ID
```

## تست سریع

```
https://دامنه‌شما.up.railway.app/managepanel/   ← باید پنل را نشان دهد
https://دامنه‌شما.up.railway.app/cdn            ← باید "Bad Request" بدهد (یعنی به Xray رسیده)
```

## نکات مهم

- تنظیمات پنل (کاربران، اینباندها) روی فایل‌سیستم موقت کانتینر ذخیره می‌شود. برای جلوگیری از پاک شدن با هر Redeploy، از بخش **Volumes** در Railway یک Volume به مسیر `/etc/x-ui` وصل کنید.
- اگر خواستید بعداً به Postgres سوییچ کنید (برای تعداد کاربر بالا)، باید Dockerfile و start.sh را برای نصب/اتصال Postgres جداگانه اصلاح کنید — این نسخه فعلی فقط SQLite را پشتیبانی می‌کند.
