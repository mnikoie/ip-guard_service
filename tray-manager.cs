// IP Guard Tray Manager
// A small WinForms controller for the project batch files.  It runs without a
// console window and updates each menu action from the actual local state.
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Text;
using System.IO;
using System.ServiceProcess;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

internal static class IPGuardTrayManager
{
    private const string ServiceName = "ipguardservice.exe";
    private const string ServiceDisplayName = "IPGuardService";
    private static readonly string AppDirectory = Path.GetDirectoryName(Application.ExecutablePath);
    private static readonly string RuntimeDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "IPGuardService");
    private static readonly string TrayPidFile = Path.Combine(RuntimeDirectory, "tray-manager.pid");
    private static readonly string LanguageFile = Path.Combine(RuntimeDirectory, "tray-language.txt");
    private static readonly string OverlayPidFile = @"C:\ProgramData\IPGuardService\overlay.pid";
    private static readonly string StatusFile = @"C:\ProgramData\IPGuardService\status.json";
    private static readonly string StartupDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.Startup));
    private static readonly string OverlayShortcut = Path.Combine(StartupDirectory, "IPGuardAlert.lnk");

    private static NotifyIcon trayIcon;
    private static ContextMenuStrip menu;
    private static ToolStripMenuItem serviceStatusItem;
    private static ToolStripMenuItem networkStatusItem;
    private static ToolStripMenuItem dependencyActionItem;
    private static ToolStripMenuItem serviceInstallActionItem;
    private static ToolStripMenuItem startServiceItem;
    private static ToolStripMenuItem stopServiceItem;
    private static ToolStripMenuItem restartServiceItem;
    private static ToolStripMenuItem overlayActionItem;
    private static ToolStripMenuItem overlayStatusItem;
    private static ToolStripMenuItem viewLogItem;
    private static ToolStripMenuItem editConfigItem;
    private static ToolStripMenuItem openFolderItem;
    private static ToolStripMenuItem exitItem;
    private static ToolStripMenuItem aboutItem;
    private static ToolStripMenuItem languageMenuItem;
    private static ToolStripMenuItem persianLanguageItem;
    private static ToolStripMenuItem englishLanguageItem;
    private static PrivateFontCollection fontCollection;
    private static Font menuFont;
    private static ApplicationContext applicationContext;
    private static string language = "fa";

    [STAThread]
    private static void Main()
    {
        bool createdNew;
        using (Mutex mutex = new Mutex(true, "Local\\IPGuardTrayManagerExe", out createdNew))
        {
            if (!createdNew) return;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Directory.CreateDirectory(RuntimeDirectory);
            language = LoadLanguage();
            File.WriteAllText(TrayPidFile, Process.GetCurrentProcess().Id.ToString());
            try
            {
                ConfigureUi();
                applicationContext = new ApplicationContext();
                Application.Run(applicationContext);
            }
            finally
            {
                if (trayIcon != null) { trayIcon.Visible = false; trayIcon.Dispose(); }
                if (menuFont != null) menuFont.Dispose();
                if (fontCollection != null) fontCollection.Dispose();
                TryDelete(TrayPidFile);
            }
        }
    }

    private static void ConfigureUi()
    {
        fontCollection = new PrivateFontCollection();
        try
        {
            string fontPath = Path.Combine(AppDirectory, "Vazirmatn-Regular.ttf");
            if (File.Exists(fontPath)) fontCollection.AddFontFile(fontPath);
        }
        catch { }
        menuFont = fontCollection.Families.Length > 0
            ? new Font(fontCollection.Families[0], 9.5f, FontStyle.Regular)
            : new Font("Tahoma", 9.5f, FontStyle.Regular);

        menu = new ContextMenuStrip();
        menu.Font = menuFont;
        menu.RightToLeft = language == "fa" ? RightToLeft.Yes : RightToLeft.No;
        menu.RenderMode = ToolStripRenderMode.System;
        menu.Opening += delegate { RefreshMenu(); };

        networkStatusItem = AddDisabled(T("وضعیت شبکه: در حال بررسی…", "Network: checking…"), Color.DimGray);
        serviceStatusItem = AddDisabled(T("سرویس ویندوز: در حال بررسی…", "Windows service: checking…"), Color.DimGray);
        menu.Items.Add(new ToolStripSeparator());

        dependencyActionItem = AddAction("", delegate { ToggleDependencies(); });
        serviceInstallActionItem = AddAction("", delegate { ToggleServiceInstall(); });
        startServiceItem = AddAction("", delegate { StartMaintenance("start-service.bat", true); });
        stopServiceItem = AddAction("", delegate { StartMaintenance("stop-service.bat", true); });
        restartServiceItem = AddAction("", delegate { StartMaintenance("4-restart-service.bat", true); });
        menu.Items.Add(new ToolStripSeparator());

        overlayStatusItem = AddDisabled(T("هشدار دسکتاپ: در حال بررسی…", "Desktop alert: checking…"), Color.DimGray);
        overlayActionItem = AddAction("", delegate { ToggleOverlay(); });
        menu.Items.Add(new ToolStripSeparator());

        viewLogItem = AddAction("", delegate { StartMaintenance("5-view-log.bat", false); });
        editConfigItem = AddAction("", delegate { OpenConfig(); });
        openFolderItem = AddAction("", delegate { OpenProjectFolder(); });
        aboutItem = AddAction("", delegate { ShowAbout(); });
        menu.Items.Add(new ToolStripSeparator());
        languageMenuItem = new ToolStripMenuItem();
        persianLanguageItem = new ToolStripMenuItem();
        englishLanguageItem = new ToolStripMenuItem();
        persianLanguageItem.Click += delegate { SetLanguage("fa"); };
        englishLanguageItem.Click += delegate { SetLanguage("en"); };
        languageMenuItem.DropDownItems.Add(persianLanguageItem);
        languageMenuItem.DropDownItems.Add(englishLanguageItem);
        menu.Items.Add(languageMenuItem);
        menu.Items.Add(new ToolStripSeparator());
        exitItem = AddAction("", delegate { applicationContext.ExitThread(); });

        trayIcon = new NotifyIcon();
        try { trayIcon.Icon = new Icon(Path.Combine(AppDirectory, "assets", "ip-guard-ai.ico")); }
        catch { trayIcon.Icon = SystemIcons.Shield; }
        trayIcon.Text = T("IP Guard — در حال بررسی", "IP Guard — checking status");
        trayIcon.ContextMenuStrip = menu;
        trayIcon.Visible = true;
        trayIcon.DoubleClick += delegate { StartMaintenance("5-view-log.bat", false); };

        System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();
        timer.Interval = 3000;
        timer.Tick += delegate { RefreshMenu(); };
        timer.Start();
        RefreshMenu();
    }

    private static ToolStripMenuItem AddDisabled(string text, Color color)
    {
        ToolStripMenuItem item = new ToolStripMenuItem(text);
        item.Enabled = false;
        item.ForeColor = color;
        menu.Items.Add(item);
        return item;
    }

    private static ToolStripMenuItem AddAction(string text, EventHandler action)
    {
        ToolStripMenuItem item = new ToolStripMenuItem(text);
        item.Click += action;
        menu.Items.Add(item);
        return item;
    }

    private static string T(string persian, string english)
    {
        return language == "en" ? english : persian;
    }

    private static string LoadLanguage()
    {
        try
        {
            string saved = File.ReadAllText(LanguageFile).Trim().ToLowerInvariant();
            return saved == "en" ? "en" : "fa";
        }
        catch { return "fa"; }
    }

    private static void SetLanguage(string selectedLanguage)
    {
        language = selectedLanguage == "en" ? "en" : "fa";
        try { File.WriteAllText(LanguageFile, language); }
        catch { }
        menu.RightToLeft = language == "fa" ? RightToLeft.Yes : RightToLeft.No;
        RefreshMenu();
    }

    private static void RefreshStaticText()
    {
        startServiceItem.Text = T("▶ شروع سرویس", "▶ Start service");
        stopServiceItem.Text = T("■ توقف سرویس", "■ Stop service");
        restartServiceItem.Text = T("↻ راه‌اندازی مجدد سرویس", "↻ Restart service");
        viewLogItem.Text = T("نمایش وضعیت و لاگ", "Show current status and log");
        editConfigItem.Text = T("ویرایش تنظیمات", "Edit configuration");
        openFolderItem.Text = T("باز کردن پوشهٔ پروژه", "Open project folder");
        languageMenuItem.Text = T("زبان / Language", "Language / زبان");
        persianLanguageItem.Text = (language == "fa" ? "✓ " : "") + "فارسی";
        englishLanguageItem.Text = (language == "en" ? "✓ " : "") + "English";
        exitItem.Text = T("خروج از مدیر IP Guard", "Exit IP Guard Manager");
        aboutItem.Text = T("دربارهٔ من", "About the developer");
    }

    private static void RefreshMenu()
    {
        RefreshStaticText();
        bool dependenciesInstalled = DependenciesInstalled();
        dependencyActionItem.Text = dependenciesInstalled
            ? T("✓ وابستگی‌ها نصب است — حذف وابستگی‌ها", "✓ Dependencies installed — remove dependencies")
            : T("✕ وابستگی‌ها نصب نیست — نصب وابستگی‌ها", "✕ Dependencies not installed — install dependencies");
        dependencyActionItem.ForeColor = dependenciesInstalled ? Color.ForestGreen : Color.Firebrick;

        ServiceControllerStatus? serviceStatus = GetServiceStatus();
        bool serviceInstalled = serviceStatus.HasValue;
        if (!serviceInstalled)
        {
            serviceStatusItem.Text = T("✕ سرویس ویندوز نصب نیست", "✕ Windows service is not installed");
            serviceStatusItem.ForeColor = Color.Firebrick;
        }
        else if (serviceStatus.Value == ServiceControllerStatus.Running)
        {
            serviceStatusItem.Text = T("✓ سرویس ویندوز: در حال اجرا", "✓ Windows service: running");
            serviceStatusItem.ForeColor = Color.ForestGreen;
        }
        else
        {
            serviceStatusItem.Text = T("! سرویس ویندوز: ", "! Windows service: ") + ServiceStatusText(serviceStatus.Value);
            serviceStatusItem.ForeColor = Color.DarkGoldenrod;
        }
        serviceInstallActionItem.Text = serviceInstalled
            ? T("✓ سرویس نصب است — توقف و حذف سرویس", "✓ Service installed — stop and remove service")
            : T("✕ سرویس نصب نیست — نصب سرویس ویندوز", "✕ Service not installed — install Windows service");
        serviceInstallActionItem.ForeColor = serviceInstalled ? Color.ForestGreen : Color.Firebrick;
        startServiceItem.Enabled = serviceInstalled && serviceStatus.Value != ServiceControllerStatus.Running;
        stopServiceItem.Enabled = serviceInstalled && serviceStatus.Value == ServiceControllerStatus.Running;
        restartServiceItem.Enabled = serviceInstalled;
        startServiceItem.ForeColor = startServiceItem.Enabled ? Color.ForestGreen : Color.DimGray;
        stopServiceItem.ForeColor = stopServiceItem.Enabled ? Color.DarkOrange : Color.DimGray;
        restartServiceItem.ForeColor = restartServiceItem.Enabled ? Color.RoyalBlue : Color.DimGray;

        bool overlayInstalled = File.Exists(OverlayShortcut);
        bool overlayRunning = overlayInstalled && ProcessFromPidFileIsRunning(OverlayPidFile);
        overlayStatusItem.Text = overlayRunning
            ? T("✓ هشدار دسکتاپ: فعال و در حال اجرا", "✓ Desktop alert: active and running")
            : overlayInstalled ? T("! هشدار دسکتاپ: نصب شده، اما اجرا نیست", "! Desktop alert: installed but not running") : T("✕ هشدار دسکتاپ: غیرفعال", "✕ Desktop alert: inactive");
        overlayStatusItem.ForeColor = overlayRunning ? Color.ForestGreen : overlayInstalled ? Color.DarkGoldenrod : Color.Firebrick;
        overlayActionItem.Text = overlayInstalled
            ? T("✓ هشدار دسکتاپ نصب است — حذف هشدار", "✓ Desktop alert installed — remove alert")
            : T("✕ هشدار دسکتاپ غیرفعال است — نصب هشدار", "✕ Desktop alert inactive — install alert");
        overlayActionItem.ForeColor = overlayInstalled ? Color.ForestGreen : Color.Firebrick;

        RefreshNetworkState();
    }

    private static void RefreshNetworkState()
    {
        string raw;
        try { raw = File.ReadAllText(StatusFile); }
        catch
        {
            networkStatusItem.Text = T("! وضعیت شبکه: هنوز از سرویس دریافت نشده", "! Network state: not received from service yet");
            networkStatusItem.ForeColor = Color.DarkGoldenrod;
            trayIcon.Text = T("IP Guard — در انتظار سرویس", "IP Guard — waiting for service");
            return;
        }
        bool trusted = Regex.IsMatch(raw, "\\\"state\\\"\\s*:\\s*\\\"TRUSTED\\\"", RegexOptions.IgnoreCase);
        bool unsafeState = Regex.IsMatch(raw, "\\\"state\\\"\\s*:\\s*\\\"UNSAFE\\\"", RegexOptions.IgnoreCase);
        if (trusted)
        {
            networkStatusItem.Text = T("✓ وضعیت شبکه: امن", "✓ Network state: trusted");
            networkStatusItem.ForeColor = Color.ForestGreen;
            trayIcon.Text = T("IP Guard — شبکه امن است", "IP Guard — trusted network");
        }
        else if (unsafeState)
        {
            networkStatusItem.Text = T("! وضعیت شبکه: محافظت فعال است", "! Network state: protection active");
            networkStatusItem.ForeColor = Color.Firebrick;
            trayIcon.Text = T("IP Guard — محافظت فعال است", "IP Guard — protection active");
        }
        else
        {
            networkStatusItem.Text = T("! وضعیت شبکه: در حال به‌روزرسانی", "! Network state: updating");
            networkStatusItem.ForeColor = Color.DarkGoldenrod;
            trayIcon.Text = T("IP Guard — در حال بررسی", "IP Guard — checking status");
        }
    }

    private static bool DependenciesInstalled()
    {
        return File.Exists(Path.Combine(AppDirectory, "node_modules", "axios", "package.json"))
            && File.Exists(Path.Combine(AppDirectory, "node_modules", "winston", "package.json"))
            && Directory.Exists(Path.Combine(AppDirectory, "node_modules", "node-windows"));
    }

    private static ServiceControllerStatus? GetServiceStatus()
    {
        try
        {
            foreach (ServiceController service in ServiceController.GetServices())
            {
                using (service)
                {
                    if (String.Equals(service.ServiceName, ServiceName, StringComparison.OrdinalIgnoreCase)
                        || String.Equals(service.DisplayName, ServiceDisplayName, StringComparison.OrdinalIgnoreCase)) return service.Status;
                }
            }
        }
        catch { }
        return null;
    }

    private static string ServiceStatusText(ServiceControllerStatus status)
    {
        if (status == ServiceControllerStatus.Stopped) return T("متوقف", "stopped");
        if (status == ServiceControllerStatus.StartPending) return T("در حال شروع", "starting");
        if (status == ServiceControllerStatus.StopPending) return T("در حال توقف", "stopping");
        if (status == ServiceControllerStatus.Paused) return T("متوقف موقت", "paused");
        return T("نامشخص", "unknown");
    }

    private static bool ProcessFromPidFileIsRunning(string file)
    {
        try
        {
            int processId;
            if (!Int32.TryParse(File.ReadAllText(file).Trim(), out processId)) return false;
            Process process = Process.GetProcessById(processId);
            return !process.HasExited;
        }
        catch { return false; }
    }

    private static void ToggleDependencies()
    {
        if (DependenciesInstalled())
        {
            if (GetServiceStatus().HasValue)
            {
                string warning = T(
                    "سرویس ویندوز IP Guard هنوز نصب است.\n\nبرای جلوگیری از باقی‌ماندن سرویس خراب، با انتخاب «بله» ابتدا سرویس متوقف و حذف می‌شود و سپس وابستگی‌های همین پروژه پاک می‌شوند.\n\nبا انتخاب «خیر»، هیچ چیزی حذف نمی‌شود.",
                    "The IP Guard Windows service is still installed.\n\nTo avoid leaving a broken service behind, choose Yes to stop and remove the service first, then remove this project's dependencies.\n\nChoose No to cancel without removing anything.");
                if (Confirm(warning, T("حذف وابستگی‌ها و سرویس", "Remove dependencies and service")))
                    StartMaintenance("0-uninstall-dependencies.bat", true, "/remove-service");
            }
            else if (Confirm(T("وابستگی‌های همین پروژه (پوشهٔ node_modules) حذف شوند؟\nNode.js ویندوز حذف نمی‌شود.", "Remove this project's node_modules folder?\nSystem-wide Node.js will not be removed."), T("حذف وابستگی‌ها", "Remove dependencies")))
            {
                StartMaintenance("0-uninstall-dependencies.bat", false);
            }
        }
        else StartMaintenance("1-install-dependencies.bat", false);
    }

    private static void ToggleServiceInstall()
    {
        if (GetServiceStatus().HasValue)
        {
            if (Confirm(T("سرویس IPGuardService متوقف و حذف شود؟", "Stop and remove IPGuardService?"), T("حذف سرویس", "Remove service")))
                StartMaintenance("3-stop-and-uninstall-service.bat", true);
        }
        else StartMaintenance("2-install-service.bat", true);
    }

    private static void ToggleOverlay()
    {
        if (File.Exists(OverlayShortcut))
        {
            if (Confirm(T("هشدار دسکتاپ و اجرای خودکار آن حذف شود؟", "Remove the desktop alert and its automatic startup?"), T("حذف هشدار دسکتاپ", "Remove desktop alert")))
                StartMaintenance("uninstall-overlay.bat", false);
        }
        else StartMaintenance("install-overlay.bat", false);
    }

    private static bool Confirm(string message, string title)
    {
        return MessageBox.Show(message, title + " — IP Guard", MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2, DialogOptions()) == DialogResult.Yes;
    }

    private static MessageBoxOptions DialogOptions()
    {
        return language == "fa" ? MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign : 0;
    }

    private static void StartMaintenance(string fileName, bool requiresAdministrator)
    {
        StartMaintenance(fileName, requiresAdministrator, "");
    }

    private static void StartMaintenance(string fileName, bool requiresAdministrator, string arguments)
    {
        string path = Path.Combine(AppDirectory, fileName);
        if (!File.Exists(path))
        {
            MessageBox.Show(T("فایل موردنیاز پیدا نشد:\n", "Required file was not found:\n") + path, "IP Guard", MessageBoxButtons.OK, MessageBoxIcon.Error,
                MessageBoxDefaultButton.Button1, DialogOptions());
            return;
        }
        try
        {
            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe";
            info.Arguments = String.IsNullOrWhiteSpace(arguments)
                ? "/k \"\"" + path + "\"\""
                : "/k \"\"" + path + "\" " + arguments + "\"";
            info.WorkingDirectory = AppDirectory;
            info.UseShellExecute = true;
            if (requiresAdministrator) info.Verb = "runas";
            Process.Start(info);
        }
        catch (System.ComponentModel.Win32Exception) { }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "IP Guard", MessageBoxButtons.OK, MessageBoxIcon.Error,
                MessageBoxDefaultButton.Button1, DialogOptions());
        }
    }

    private static void OpenConfig()
    {
        string config = Path.Combine(AppDirectory, "config.json");
        if (File.Exists(config)) Process.Start("notepad.exe", "\"" + config + "\"");
    }

    private static void OpenProjectFolder()
    {
        Process.Start("explorer.exe", "\"" + AppDirectory + "\"");
    }

    private static void ShowAbout()
    {
        string message = T(
            "IP Guard Service\n\nتوسعه‌دهنده: سید محمد علی نیکوئی\nتلفن: 09132675400\nایمیل: m.nikoie2005@gmail.com\n\nابزار محافظت از برنامه‌ها هنگام تغییر ناخواستهٔ موقعیت IP.",
            "IP Guard Service\n\nDeveloper: Seyed Mohammad Ali Nikoei\nPhone: +98 913 267 5400\nEmail: m.nikoie2005@gmail.com\n\nA desktop-app guard for unexpected public-IP location changes.");
        MessageBox.Show(message, T("دربارهٔ من — IP Guard", "About the developer — IP Guard"), MessageBoxButtons.OK,
            MessageBoxIcon.Information, MessageBoxDefaultButton.Button1, DialogOptions());
    }

    private static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); }
        catch { }
    }
}
