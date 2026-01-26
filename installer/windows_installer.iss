[Setup]
AppName=Shop Manager
AppVersion=1.0.0
AppPublisher=Shop Manager Team
AppPublisherURL=https://shopmanager.com
DefaultDirName={autopf64}\ShopManager
DefaultGroupName=Shop Manager
UninstallDisplayIcon={app}\shop_manager.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputBaseFilename=shop_manager_setup
OutputDir=Output
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\Shop Manager"; Filename: "{app}\shop_manager.exe"
Name: "{autodesktop}\Shop Manager"; Filename: "{app}\shop_manager.exe"; Tasks: desktopicon
Name: "{group}\Uninstall Shop Manager"; Filename: "{uninstallexe}"

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Installation des dépendances Microsoft Visual C++..."; Flags: waituntilterminated
Filename: "{app}\shop_manager.exe"; Description: "{cm:LaunchProgram,Shop Manager}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;