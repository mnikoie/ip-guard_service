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
    private const string ServiceName = "IPGuardService";
    private static readonly string AppDirectory = Path.GetDirectoryName(Application.ExecutablePath);
    private static readonly string RuntimeDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "IPGuardService");
    private static readonly string TrayPidFile = Path.Combine(RuntimeDirectory, "tray-manager.pid");
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
    private static PrivateFontCollection fontCollection;
    private static Font menuFont;
    private static ApplicationContext applicationContext;

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
        menu.RightToLeft = RightToLeft.Yes;
        menu.RenderMode = ToolStripRenderMode.System;
        menu.Opening += delegate { RefreshMenu(); };

        networkStatusItem = AddDisabled("وضعیت شبکه: در حال بررسی…", Color.DimGray);
        serviceStatusItem = AddDisabled("سرویس ویندوز: در حال بررسی…", Color.DimGray);
        menu.Items.Add(new ToolStripSeparator());

        dependencyActionItem = AddAction("", delegate { ToggleDependencies(); });
        serviceInstallActionItem = AddAction("", delegate { ToggleServiceInstall(); });
        startServiceItem = AddAction("▶ شروع سرویس", delegate { StartMaintenance("start-service.bat", true); });
        stopServiceItem = AddAction("■ توقف سرویس", delegate { StartMaintenance("stop-service.bat", true); });
        restartServiceItem = AddAction("↻ راه‌اندازی مجدد سرویس", delegate { StartMaintenance("4-restart-service.bat", true); });
        menu.Items.Add(new ToolStripSeparator());

        overlayStatusItem = AddDisabled("هشدار دسکتاپ: در حال بررسی…", Color.DimGray);
        overlayActionItem = AddAction("", delegate { ToggleOverlay(); });
        menu.Items.Add(new ToolStripSeparator());

        AddAction("نمایش وضعیت و لاگ", delegate { StartMaintenance("5-view-log.bat", false); });
        AddAction("ویرایش تنظیمات", delegate { OpenConfig(); });
        AddAction("باز کردن پوشهٔ پروژه", delegate { OpenProjectFolder(); });
        menu.Items.Add(new ToolStripSeparator());
        AddAction("خروج از مدیر IP Guard", delegate { applicationContext.ExitThread(); });

        trayIcon = new NotifyIcon();
        try { trayIcon.Icon = new Icon(Path.Combine(AppDirectory, "assets", "ip-guard-ai.ico")); }
        catch { trayIcon.Icon = SystemIcons.Shield; }
        trayIcon.Text = "IP Guard — در حال بررسی";
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

    private static void RefreshMenu()
    {
        bool dependenciesInstalled = DependenciesInstalled();
        dependencyActionItem.Text = dependenciesInstalled
            ? "✓ وابستگی‌ها نصب است — حذف وابستگی‌ها"
            : "✕ وابستگی‌ها نصب نیست — نصب وابستگی‌ها";
        dependencyActionItem.ForeColor = dependenciesInstalled ? Color.ForestGreen : Color.Firebrick;

        ServiceControllerStatus? serviceStatus = GetServiceStatus();
        bool serviceInstalled = serviceStatus.HasValue;
        if (!serviceInstalled)
        {
            serviceStatusItem.Text = "✕ سرویس ویندوز نصب نیست";
            serviceStatusItem.ForeColor = Color.Firebrick;
        }
        else if (serviceStatus.Value == ServiceControllerStatus.Running)
        {
            serviceStatusItem.Text = "✓ سرویس ویندوز: در حال اجرا";
            serviceStatusItem.ForeColor = Color.ForestGreen;
        }
        else
        {
            serviceStatusItem.Text = "! سرویس ویندوز: " + ServiceStatusText(serviceStatus.Value);
            serviceStatusItem.ForeColor = Color.DarkGoldenrod;
        }
        serviceInstallActionItem.Text = serviceInstalled
            ? "✓ سرویس نصب است — توقف و حذف سرویس"
            : "✕ سرویس نصب نیست — نصب سرویس ویندوز";
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
            ? "✓ هشدار دسکتاپ: فعال و در حال اجرا"
            : overlayInstalled ? "! هشدار دسکتاپ: نصب شده، اما اجرا نیست" : "✕ هشدار دسکتاپ: غیرفعال";
        overlayStatusItem.ForeColor = overlayRunning ? Color.ForestGreen : overlayInstalled ? Color.DarkGoldenrod : Color.Firebrick;
        overlayActionItem.Text = overlayInstalled
            ? "✓ هشدار دسکتاپ نصب است — حذف هشدار"
            : "✕ هشدار دسکتاپ غیرفعال است — نصب هشدار";
        overlayActionItem.ForeColor = overlayInstalled ? Color.ForestGreen : Color.Firebrick;

        RefreshNetworkState();
    }

    private static void RefreshNetworkState()
    {
        string raw;
        try { raw = File.ReadAllText(StatusFile); }
        catch
        {
            networkStatusItem.Text = "! وضعیت شبکه: هنوز از سرویس دریافت نشده";
            networkStatusItem.ForeColor = Color.DarkGoldenrod;
            trayIcon.Text = "IP Guard — در انتظار سرویس";
            return;
        }
        bool trusted = Regex.IsMatch(raw, "\\\"state\\\"\\s*:\\s*\\\"TRUSTED\\\"", RegexOptions.IgnoreCase);
        bool unsafeState = Regex.IsMatch(raw, "\\\"state\\\"\\s*:\\s*\\\"UNSAFE\\\"", RegexOptions.IgnoreCase);
        if (trusted)
        {
            networkStatusItem.Text = "✓ وضعیت شبکه: امن";
            networkStatusItem.ForeColor = Color.ForestGreen;
            trayIcon.Text = "IP Guard — شبکه امن است";
        }
        else if (unsafeState)
        {
            networkStatusItem.Text = "! وضعیت شبکه: محافظت فعال است";
            networkStatusItem.ForeColor = Color.Firebrick;
            trayIcon.Text = "IP Guard — محافظت فعال است";
        }
        else
        {
            networkStatusItem.Text = "! وضعیت شبکه: در حال به‌روزرسانی";
            networkStatusItem.ForeColor = Color.DarkGoldenrod;
            trayIcon.Text = "IP Guard — در حال بررسی";
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
                    if (String.Equals(service.ServiceName, ServiceName, StringComparison.OrdinalIgnoreCase)) return service.Status;
                }
            }
        }
        catch { }
        return null;
    }

    private static string ServiceStatusText(ServiceControllerStatus status)
    {
        if (status == ServiceControllerStatus.Stopped) return "متوقف";
        if (status == ServiceControllerStatus.StartPending) return "در حال شروع";
        if (status == ServiceControllerStatus.StopPending) return "در حال توقف";
        if (status == ServiceControllerStatus.Paused) return "متوقف موقت";
        return "نامشخص";
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
            if (Confirm("وابستگی‌های همین پروژه (پوشهٔ node_modules) حذف شوند؟\nNode.js ویندوز حذف نمی‌شود.", "حذف وابستگی‌ها"))
                StartMaintenance("0-uninstall-dependencies.bat", false);
        }
        else StartMaintenance("1-install-dependencies.bat", false);
    }

    private static void ToggleServiceInstall()
    {
        if (GetServiceStatus().HasValue)
        {
            if (Confirm("سرویس IPGuardService متوقف و حذف شود؟", "حذف سرویس"))
                StartMaintenance("3-stop-and-uninstall-service.bat", true);
        }
        else StartMaintenance("2-install-service.bat", true);
    }

    private static void ToggleOverlay()
    {
        if (File.Exists(OverlayShortcut))
        {
            if (Confirm("هشدار دسکتاپ و اجرای خودکار آن حذف شود؟", "حذف هشدار دسکتاپ"))
                StartMaintenance("uninstall-overlay.bat", false);
        }
        else StartMaintenance("install-overlay.bat", false);
    }

    private static bool Confirm(string message, string title)
    {
        return MessageBox.Show(message, title + " — IP Guard", MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2, MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign) == DialogResult.Yes;
    }

    private static void StartMaintenance(string fileName, bool requiresAdministrator)
    {
        string path = Path.Combine(AppDirectory, fileName);
        if (!File.Exists(path))
        {
            MessageBox.Show("فایل موردنیاز پیدا نشد:\n" + path, "IP Guard", MessageBoxButtons.OK, MessageBoxIcon.Error,
                MessageBoxDefaultButton.Button1, MessageBoxOptions.RtlReading | MessageBoxOptions.RightAlign);
            return;
        }
        try
        {
            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe";
            info.Arguments = "/k \"\"" + path + "\"\"";
            info.WorkingDirectory = AppDirectory;
            info.UseShellExecute = true;
            if (requiresAdministrator) info.Verb = "runas";
            Process.Start(info);
        }
        catch (System.ComponentModel.Win32Exception) { }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "IP Guard", MessageBoxButtons.OK, MessageBoxIcon.Error);
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

    private static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); }
        catch { }
    }
}
