; Project Vice installer for Windows (Inno Setup 6 or newer).
; Build the app folder first (scripts/build-windows-msys2.sh makes ProjectVice-Win), then:
;   ISCC scripts\project-vice.iss
; The installer is written to dist\ProjectVice-Setup-<version>.exe.
;
; It installs for everyone on the computer, into Program Files, as Windows apps usually do:
; it asks for administrator rights, adds a Start menu entry, and appears under Installed apps
; with an uninstaller. Each person's own settings and paired consoles stay in their own
; account (HKEY_CURRENT_USER\Software\Project Vice) and are kept when the app is updated.

#define MyAppName "Project Vice"
#define MyAppPublisher "Project Vice"
#define MyAppURL "https://github.com/mahtab-ali/project-vice"
#define MyAppExeName "ProjectVice.exe"
#define MyAppPath "..\ProjectVice-Win"
#define MyAppVersion() \
  GetVersionComponents(MyAppPath + "\" + MyAppExeName, Local[0], Local[1], Local[2], Local[3]), \
  Str(Local[0]) + "." + Str(Local[1]) + "." + Str(Local[2])

[Setup]
; Identifies this app to Windows. Never reuse it for another app; never change it for this one.
AppId={{6F0B8C0E-6C1B-4E0C-9E53-7E5F0C1D2A41}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
VersionInfoVersion={#MyAppVersion}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} Setup
VersionInfoCompany={#MyAppPublisher}

; Program Files, for all users
PrivilegesRequired=admin
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

LicenseFile=..\LICENSES\AGPL-3.0-only-OpenSSL.txt
SetupIconFile=..\gui\vice.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
OutputDir=..\dist
OutputBaseFilename=ProjectVice-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; An update closes the running app first and offers to start it again
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyAppPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Started as the person who ran Setup, not as administrator
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent runasoriginaluser

[UninstallDelete]
; Files the app writes beside itself while running; settings in the user's account are left alone
Type: filesandordirs; Name: "{app}\cache"
