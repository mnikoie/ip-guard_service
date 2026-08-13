# سرویس IP Guard

[English README](README.md)

IP Guard یک سرویس واقعی ویندوز با سیاست **fail-closed** است. این سرویس فقط هنگامی به برنامه‌های تعیین‌شده اجازهٔ اجرا می‌دهد که آی‌پی عمومی سیستم با موفقیت در یکی از کشورهای امن تأیید شده باشد.

هدف پروژه این است که هنگام قطع‌شدن VPN، تغییر سرور VPN یا تغییر ناخواستهٔ موقعیت آی‌پی، برنامه‌هایی مانند Claude، ChatGPT، Perplexity و Cursor پیش از ادامهٔ استفاده بسته شوند؛ در نتیجه ریسک ورود اتفاقی از یک شبکه یا موقعیت غیرمنتظره کمتر می‌شود.

> این ابزار هیچ محدودیتی را دور نمی‌زند، آی‌پی را مخفی نمی‌کند و تضمین نمی‌دهد حساب کاربری Ban نشود. رعایت قوانین، شرایط استفاده و سیاست‌های امنیتی هر سرویس کاملاً بر عهدهٔ کاربر است.

## قابلیت‌ها

- نصب به‌صورت Windows Service با نام `IPGuardService` و اجرای خودکار بعد از روشن‌شدن ویندوز
- بررسی آی‌پی و کشور با چند API جایگزین
- ساخت اتصال تازه در هر درخواست؛ مقاوم در برابر تغییر VPN adapter
- مدل Allowlist: فقط کشورهایی که در `trustedCountryCodes` هستند امن‌اند
- رفتار fail-closed برای ایران، کشور ناشناخته، کشور خارج از لیست، timeout، خطای API و قطع اینترنت
- بستن اجباری پردازه و زیرپردازه‌ها با `taskkill /F /T`
- تکرار Kill هر ۱۰۰ میلی‌ثانیه در حالت ناامن
- هشدار فارسی RTL با فونت Vazirmatn؛ بدون گرفتن فوکوس و بدون مسدودکردن کلیک برنامه‌های دیگر
- نمایش رنگی آخرین وضعیت در `5-view-log.bat`
- آیکون مدیریت در System Tray ویندوز با منوی راست‌کلیک برای همهٔ عملیات اصلی

## شروع سریع

1. فایل [`config.json`](config.json) را با دقت تنظیم کنید؛ مخصوصاً `trustedCountryCodes` و `processesToKill`.
2. [`1-install-dependencies.bat`](1-install-dependencies.bat) را اجرا کنید.
3. [`2-install-service.bat`](2-install-service.bat) را با **Run as administrator** اجرا کنید.
4. برای فعال‌شدن هشدار گرافیکی، [`install-overlay.bat`](install-overlay.bat) را یک‌بار در حساب کاربری موردنظر اجرا کنید.
5. [`install-tray-manager.bat`](install-tray-manager.bat) را اجرا کنید تا آیکون سپر IP Guard کنار ساعت ویندوز ایجاد شود.
6. برای دیدن آخرین وضعیت رنگی، [`5-view-log.bat`](5-view-log.bat) را اجرا کنید.

راهنمای کامل: [فارسی](docs/INSTALLATION.fa.md) | [English](docs/INSTALLATION.md)

## آموزش تصویری سریع

![راهنمای تصویری نصب و اجرای IP Guard](docs/images/quick-start-fa.png)

[English visual quick-start guide](docs/images/quick-start-en.png)

## دربارهٔ ما

توسعه‌دهنده: **سید محمد علی نیکوئی**

- تلفن: [09132675400](tel:+989132675400)
- ایمیل: [m.nikoie2005@gmail.com](mailto:m.nikoie2005@gmail.com)

جزئیات بیشتر: [دربارهٔ پروژه و تماس](docs/ABOUT.fa.md)

## تنظیمات مهم

| کلید | کاربرد |
| --- | --- |
| `trustedCountryCodes` | فقط این کدهای دوحرفی کشور امن هستند؛ بقیه ناامن‌اند. |
| `processesToKill` | نام دقیق فایل اجرایی، مانند `ChatGPT.exe`. |
| `checkIntervalMs` | فاصلهٔ بررسی آی‌پی؛ پیش‌فرض ۵ ثانیه. |
| `killIntervalMs` | فاصلهٔ Kill در حالت ناامن؛ پیش‌فرض ۱۰۰ میلی‌ثانیه. |
| `requestTimeoutMs` | حداکثر زمان هر درخواست lookup؛ پیش‌فرض ۵ ثانیه. |
| `ipApiEndpoints` | APIهای lookup به‌ترتیب fallback. |

پس از ویرایش `config.json`، [`4-restart-service.bat`](4-restart-service.bat) را با دسترسی Administrator اجرا کنید.

## منوی آیکون کنار ساعت ویندوز

با اجرای [`install-tray-manager.bat`](install-tray-manager.bat)، آیکون اختصاصی «محافظ AI» در **System Tray / Notification Area** کنار ساعت ویندوز قرار می‌گیرد. اگر آیکون دیده نشد، فلش `^` کنار ساعت را باز کنید. با راست‌کلیک روی آن می‌توانید نصب وابستگی‌ها، نصب/حذف/Restart سرویس، نمایش وضعیت، نصب/حذف Overlay، ویرایش تنظیمات و بازکردن پوشهٔ پروژه را انجام دهید.

گزینه‌های مربوط به سرویس، پنجرهٔ تأیید Administrator ویندوز را نمایش می‌دهند. این آیکون عمداً در Notification Area است—not یک پنجرهٔ Taskbar—تا بدون بازماندن پنجرهٔ برنامه، همیشه در دسترس و دارای منوی راست‌کلیک باشد.

## نکات بسیار مهم

- تا زمانی که اولین lookup امن با موفقیت انجام نشود، سرویس وضعیت را ناامن می‌داند؛ بنابراین ممکن است برنامه‌های داخل `processesToKill` در شروع سرویس فوراً بسته شوند.
- برنامه‌های سیستمی ویندوز، آنتی‌ویروس، shell، installer یا برنامه‌های دارای کار ذخیره‌نشده را در فهرست Kill قرار ندهید.
- قطع اینترنت عمداً ناامن تلقی می‌شود؛ این انتخاب امنیت را بیشتر و احتمال بسته‌شدن برنامه در قطعی اینترنت را نیز بیشتر می‌کند.
- سرویس برای تشخیص کشور، آی‌پی عمومی را به APIهای ثالث می‌فرستد؛ جزئیات در [Privacy](docs/PRIVACY.md) آمده است.

## مستندات

- [نصب و استفادهٔ فارسی](docs/INSTALLATION.fa.md)
- [راهنمای انگلیسی](docs/INSTALLATION.md)
- [معماری](docs/ARCHITECTURE.md)
- [رفع اشکال](docs/TROUBLESHOOTING.md)
- [حریم خصوصی](docs/PRIVACY.md)
- [مشارکت](CONTRIBUTING.md)
- [سیاست امنیتی](SECURITY.md)
- [دربارهٔ پروژه و تماس](docs/ABOUT.fa.md)

## مجوز

کد پروژه تحت [MIT](LICENSE) منتشر می‌شود. فایل‌های فونت Vazirmatn تحت [SIL Open Font License 1.1](licenses/OFL-1.1.txt) هستند؛ [اعلان وابستگی‌های شخص ثالث](THIRD_PARTY_NOTICES.md) را ببینید.
