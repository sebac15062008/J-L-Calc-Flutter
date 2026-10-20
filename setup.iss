; ============================================================================
; Script de Inno Setup para J&L Calc (version Flutter Desktop)
; Estructura instalada:
;   {app}\jl_calc.exe            (launcher)
;   {app}\flutter_windows.dll    (motor Flutter)
;   {app}\data\                 (icudtl.dat, app.so, flutter_assets\)
; ============================================================================

#define MyAppName "J&L Calc"
#define MyAppVersion "1.0"
#define MyAppPublisher "J&L"
#define MyAppExeName "jl_calc.exe"

[Setup]
AppId={{E1A2B3C4-D5E6-4F7A-8B9C-0D1E2F3A4B5D}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=J&L Calc Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=C:\jlcalc\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
CloseApplications=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Tareas adicionales"

[Files]
; Launcher + motor Flutter
Source: "C:\jlcalc\build\windows\x64\runner\Release\jl_calc.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\jlcalc\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Carpeta data completa (icudtl.dat, app.so, flutter_assets\)
Source: "C:\jlcalc\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,#MyAppName}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Ejecutar {#MyAppName}"; Flags: nowait postinstall skipifsilent
