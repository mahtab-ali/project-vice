; Project Vice installer for Windows (Inno Setup 6 or newer).
; Build the app folder first (scripts/build-windows-msys2.sh makes ProjectVice-Win), then:
;   ISCC scripts\project-vice.iss
; The installer is written to dist\ProjectVice-Setup-<version>.exe. It installs for the
; current user and needs no administrator rights.

#define MyAppName "Project Vice"
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
AppPublisher=Project Vice
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
LicenseFile=..\LICENSES\AGPL-3.0-only-OpenSSL.txt
SetupIconFile=..\gui\vice.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\dist
OutputBaseFilename=ProjectVice-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
