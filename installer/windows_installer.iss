[Setup]
AppName=ShopManager
AppVersion=1.0.0
DefaultDirName={autopf64}\ShopManager
DefaultGroupName=ShopManager
UninstallDisplayIcon={app}\shop_manager.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputBaseFilename=shop_manager_setup
OutputDir=Output
AppPublisher=Your Company Name
AppPublisherURL=https://yourcompany.com
AppSupportURL=https://yourcompany.com/support
AppUpdatesURL=https://yourcompany.com/updates

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\ShopManager"; Filename: "{app}\shop_manager.exe"
Name: "{autodesktop}\ShopManager"; Filename: "{app}\shop_manager.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\shop_manager.exe"; Description: "{cm:LaunchProgram,ShopManager}"; Flags: nowait postinstall skipifsilent