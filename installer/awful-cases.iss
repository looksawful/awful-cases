#ifndef MyAppVersion
  #error MyAppVersion must be passed to ISCC with /DMyAppVersion=x.y.z
#endif

#ifndef SourceExe
  #error SourceExe must be passed to ISCC with /DSourceExe=<absolute-path>
#endif

#define MyAppName "Awful Cases"
#define MyAppPublisher "looksawful"
#define MyAppExeName "Awful-Cases.exe"

[Setup]
AppId={{7A1E03F1-B337-4E80-9657-3D1E3E8DB06C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://looksawful.ru
AppSupportURL=https://github.com/looksawful/awful-cases/issues
AppUpdatesURL=https://github.com/looksawful/awful-cases/releases
DefaultDirName={localappdata}\Programs\Awful Cases
DefaultGroupName=Awful Cases
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=Awful-Cases-Setup-{#MyAppVersion}-x64
SetupIconFile=..\app\awful-cases.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "startup"; Description: "Start Awful Cases with Windows"; Flags: unchecked

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; DestName: "{#MyAppExeName}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Awful Cases"; Filename: "{app}\{#MyAppExeName}"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Awful Cases"; ValueData: """{app}\{#MyAppExeName}"""; Tasks: startup; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Awful Cases"; Flags: postinstall nowait skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Awful Cases');
end;
