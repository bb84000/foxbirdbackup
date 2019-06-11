{**************************************************************************************}
{ FoxBirdBackup : Sauvegarde et restauration des profils Firefox et Thunderbird        }
{ bb - sdtp - may 2019                                                                 }
{  ff, tb  addons.json, addonStartup.json.lz4 : Extensions                             }
{  ff, tb  extensions : dossier des extensions installées                              }
{  ff, tb  places.sqlite : marque pages et historique                                  }
{  ff, tb  favicons.sqlite : favicons                                                  }
{  ff, tb  key4.db + logins.json : identifiants et mots de passe enregistrés           }
{  ff, tb  permissions.sqlite et content-prefs.sqlite : permissions générales et sites }
{  ff, tb  search.json.mozlz4 : moteurs de recherche                                   }
{  ff, tb  persdict.dat : dictionnaire personnel                                       }
{  ff, tb  formhistory.sqlite : données de remplissage automatique des formulaires     }
{  ff, tb  cookies.sqlite : cookies  enregistrés                                       }
{  ff, tb  webappsstore.sqlite : informations sites Web                                }
{  ff, tb  chromeappsstore.sqlite : informations des pages about:xxx                   }
{  ff, tb  chrome : dossier de personnalisation                                        }
{  ff, tb  handlers.json : infos des actions lors du téléchargement                    }
{  ff, tb  xulstore.json : paramètres barres d'outils et boutons                       }
{  ff, tb  prefs.js : préférences utilisateur                                          }
{  ff, tb  cert9.db : Certificats                                                      }
{      tb  abook??.mab : Address Book                                                  }
{**************************************************************************************}

unit FoxBirdBackup1;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WINDOWS}
     Win32Proc,
  {$ENDIF} Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, Buttons, Menus, FileUtil, lazfileutils,
  strutils, lazbbutils, LazUTF8, zipper, lazbbosversion, lazbbinifiles,
  logview1;

type
  TMozApp = (ff, tb);

  TProfile=record
    Number: integer;
    Name: string;
    IsRelative : Boolean;
    Path : string;
    Default : Boolean;
    PType: TMozApp;
  end;

  TBackup=record
    FileName: string;
    FileSize: Integer;
    Profile: TProfile;
    Date: TDateTime;
    BType: TMozApp;
  end;

  TProfiles = array of TProfile;
  TBackups = array of TBackup;

  TSortType = (up, down);

  TUnZipType =(all, partial);
  { TFoxBirdBack }

  TFoxBirdBack = class(TForm)
    BtnAbout: TButton;
    BtnBack: TButton;
    BtnQuit: TButton;
    BtnLog: TButton;
    CBAutoComp: TCheckBox;
    CBCertif: TCheckBox;
    CBCookies: TCheckBox;
    CBAddress: TCheckBox;
    CBExt: TCheckBox;
    CBFav: TCheckBox;
    CBApps: TCheckBox;
    CBPass: TCheckBox;
    CBSearch: TCheckBox;
    CBSitePrefs: TCheckBox;
    CBUserPref: TCheckBox;
    CBUserStyle: TCheckBox;
    Ebackfolder: TEdit;
    EBackName: TEdit;
    ELastBkDate: TEdit;
    ELastBackup: TEdit;
    EBkDate: TEdit;
    EProfileName: TEdit;
    EProfilePath: TEdit;
    ERestPath: TEdit;
    GroupBox1: TGroupBox;
    ImgBack: TImage;
    LLastBkDate: TLabel;
    LBackFolder: TLabel;
    LBackName: TLabel;
    LLastBackup: TLabel;
    LBackupDate: TLabel;
    LBR: TListBox;
    LBS: TListBox;
    LPath: TLabel;
    LProfName: TLabel;
    LRestPath: TLabel;
    MenuItem1: TMenuItem;
    ODImpBack: TOpenDialog;
    PageControl1: TPageControl;
    PMnuLBR: TPopupMenu;
    PSelect: TPanel;
    PButtons: TPanel;
    ProgressBar1: TProgressBar;
    PStatus: TPanel;
    RBComplete: TRadioButton;
    RBExport: TRadioButton;
    RBImport: TRadioButton;
    RBFfox: TRadioButton;
    RBPartial: TRadioButton;
    RBTbird: TRadioButton;
    SDRestorePath: TSelectDirectoryDialog;
    TSBackup: TTabSheet;
    TSRestore: TTabSheet;
    procedure BtnAboutClick(Sender: TObject);
    procedure BtnBackClick(Sender: TObject);
    procedure BtnLogClick(Sender: TObject);
    procedure BtnQuitClick(Sender: TObject);
    procedure BtnRestFolderClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LBClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure RBBirdFoxClick(Sender: TObject);
    procedure RBManageClick(Sender: TObject);
  private
    first: Boolean;
    OS: String;
    OsInfo: TOSInfo;
    CRLF: String;
    CompileDateTime: TDateTime;
    version: string;
    OSTarget: String;
    UpdateURL: string;
    LangFile: TBbIniFile;
    LangStr: string;
    LangIds: TStringList;
    AppToBack: String;
    UserPath, UserAppsDataPath: String;
    ffpath, tbpath: String;
    AppdataPath, FireBack, ThunderBack: String;
    Profiles : TProfiles;
    Backups: TBackups;
    ProfilesCount : Integer;
    CurrentProfile: Integer;
    StartWithLastProfile : Integer;
    ProfileVersion: Integer;
    ReallyCanClose: boolean;
    Zcount: Integer;
    CurProfilePath: string;
    ProfileType: TMozApp;
    LastBackup: string;
    LastBackupDate: TDateTime;
    caption_prefix: string;
    default_profile_caption: string;
    LogSession: TstringList;
    delete_backup_title, delete_backup_caption, cannot_delete_bk_caption: string;
    btn_yes_caption, btn_no_caption, btn_abort_caption, btn_cancel_caption: string;
    btn_backup_caption, btn_restore_caption, btn_import_caption, btn_export_caption: string;
    cannot_save_app_open, cannot_restore_profile_locked : string;
    cannot_export, cannot_import : String;
    import_filter: string;
    restore_path_caption, export_path_caption, backup_name_to_import : string;
    progres : Integer;
    procedure ModLangue;
    function ListProfiles(app: TMozApp): boolean;
    function ListBackups(app: TMozApp): boolean;
    procedure SortArray(var Backs: TBackups; stype : TSortType);
    function EnableControls(state: boolean): boolean;
    function ZipAFolder(Folder, ZipName: string): boolean;
    function EnableRestItems(state: boolean): boolean;
    function UnZipFiles(zipname, outpath: string; uType: TUnZipType): boolean;
    procedure OnArchiveProgress(Sender: TObject; Progress: Byte; var Abort: Boolean);
    Procedure ZipperProgress(Sender : TObject; Const Pct : Double) ;
    Procedure ZipperEndFile(Sender : TObject; Const Ratio : Double) ;
  public

  end;

const
  ProfileString: array [0..1] of string = ('ff','tb');


var
  FoxBirdBack: TFoxBirdBack;

implementation

{$R *.lfm}

uses restprofsel1;
{ TFoxBirdBack }



// Creation de la forme et initialisation des variables et paths
procedure TFoxBirdBack.FormCreate(Sender: TObject);
var
  s: string;
  langfound: Boolean;
  i, x: integer;
begin
  inherited;
 // Application.CreateForm(TFLogView, FLogView);      //we need this as we use it to store log messages
  First:= true;
  LogSession:= TStringList.create;
  ReallyCanClose:= True;
  OS:= 'Unk';
  UserPath:= GetUserDir;
  UserAppsDataPath:= UserPath;
  {$IFDEF Linux}
     OS:= 'Linux';
     CRLF:= #10;
     ffpath:= UserPath+'.mozilla'+PathDelim+'firefox'+PathDelim;
     tbpath:= UserPath+'.thunderbird'+PathDelim;
     LangStr:=GetEnvironmentVariable('LANG');
     x:= pos('.', LangStr);
     LangStr:= Copy(LangStr,0, 2);
     wxbitsrun:= 0;
     GetSysInfo(OsInfo);
  {$ENDIF}
  {$IFDEF WINDOWS}
     OS:= 'Windows ';
     CRLF:= #13#10;
     // get user data folder
     s:= ExtractFilePath(ExcludeTrailingPathDelimiter(GetAppConfigDir(False)));
     if  Ord(WindowsVersion) < 7 then UserAppsDataPath:= s                     // NT to XP
     else UserAppsDataPath:= ExtractFilePath(ExcludeTrailingPathDelimiter(s))+'Roaming\';  // Vista to W10
     ffpath:= UserAppsDataPath+'Mozilla'+PathDelim+'Firefox'+PathDelim; //Profiles\<profile folder>
     tbpath:= UserAppsDataPath+'Thunderbird'+PathDelim;
     LazGetShortLanguageID(LangStr);
     GetSysInfo(OsInfo);
  {$ENDIF}
  {$IFDEF WIN32}
      OSTarget:= '32 bits';
  {$ENDIF}
  {$IFDEF WIN64}
      OSTarget:= '64 bits';
  {$ENDIF}
  // Compilation date/time
  try
    CompileDateTime:= Str2Date({$I %DATE%}, 'YYYY/MM/DD')+StrToTime({$I %TIME%});
  except
    CompileDateTime:=  now();
  end;
  version:= GetVersionInfo.ProductVersion;
   AppdataPath:= UserAppsDataPath+'foxbirdbackup'+PathDelim;
   if not DirectoryExists(AppdataPath) then CreateDir(AppdataPath);
   if FileExists(AppdataPath+'log.txt') then
   begin
     LogSession.LoadFromFile(AppdataPath+'log.txt'); // LogSession.LoadFromFile(AppdataPath+'log.txt');
     if FileExists(AppdataPath+'log.bak') then DeleteFile(AppdataPath+'log.bak');
     RenameFile(AppdataPath+'log.txt', AppdataPath+'log.bak');
   end;
   LogSession.Add(DateTimeToStr(now)+' - Open FoxbirdBackup '+Version+' '+OSTarget);
   LogSession.Add(DateTimeToStr(now)+' - '+OsInfo.VerDetail);
   LogSession.add(DateTimeToStr(now)+' - FF path: '+ffpath);
   LogSession.add(DateTimeToStr(now)+' - TB path: '+tbpath);
   FireBack:= AppdataPath+'fireback'+PathDelim;
   if not DirectoryExists(FireBack) then CreateDir(FireBack);
   ThunderBack:= AppdataPath+'thunderback'+PathDelim;
   if not DirectoryExists(ThunderBack) then CreateDir(ThunderBack);
   LogSession.add(DateTimeToStr(now)+' - FF backup path: '+FireBack);
   LogSession.add(DateTimeToStr(now)+' - TB backup path: '+ThunderBack);
   LogSession.add(DateTimeToStr(now)+' - UI Language: '+LangStr);
   LangFile:= TBbIniFile.create(ExtractFilePath(Application.ExeName)+'foxbirdbackup.lng');
   LangIds:= TStringList.Create;
   LangFound:= False;
   LangFile.ReadSections(LangIds);
   if LangIds.Count > 1 then
    For i:= 0 to LangIds.Count-1 do
    begin
      If LangIds.Strings[i] = LangStr then LangFound:= True;
    end;
  // Si la langue n'est pas traduite, alors on passe en Anglais
  If not LangFound then
  begin
    LangStr:= 'en';
  end;
  LogSession.add(DateTimeToStr(now)+' - Used Language: '+LangStr);
end;

procedure TFoxBirdBack.FormDestroy(Sender: TObject);
begin

  //FreeAndNil(LogSession);
  FreeAndNil(LangIds);
  FreeAndNil(LangFile);
end;

// Activation de la forme

procedure TFoxBirdBack.FormActivate(Sender: TObject);
//var
  //s: string;
begin
   // On n'exécute ça qu'une fois, au lancement, c'est Firefox qui est sélectionné par défaut
   if first then
  begin
    AppToBack:= 'Firefox';
    ImgBack.Picture.Icon.LoadFromResourceName(HInstance, 'iffox');

    UpdateUrl:= 'http://www.sdtp.com/versions/version.php?program=foxbirdbackup&version=';
    ModLangue;
    Caption:= Format(caption_prefix, [AppToBack]);
     LRestPath.Caption:= restore_path_caption;
    //Aboutbox.Caption:= 'A propos de FoxBirdBackup';            // in ModLangue
    AboutBox.Image1.Picture.Icon.LoadFromResourceName(HInstance, 'iffox');  ;
    AboutBox.LProductName.Caption:= GetVersionInfo.ProductName;
    AboutBox.LCopyright.Caption:= GetVersionInfo.CompanyName+' - '+DateTimeToStr(CompileDateTime);
    AboutBox.LVersion.Caption:= 'Version: '+Version+' ('+OS+OSTarget+')';
    AboutBox.UrlUpdate:= UpdateURl+Version;
    //AboutBox.LUpdate.Caption:= 'Recherche de mise à jour';      // in Modlangue
    AboutBox.UrlWebsite:=GetVersionInfo.Comments;
    PageControl1.ActivePage:= TSBackup;
    PStatus.Caption:= ' '+OsInfo.VerDetail;
    EProfilePath.Text:= ffpath;
    EBackfolder.Text:= FireBack;
    ProfileType:= ff;
    ListProfiles(ProfileType);
    ListBackups(ProfileType);
    First:= False;
  end;
end;

procedure TFoxBirdBack.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  if not ReallyCanClose then
    CloseAction := caNone else
    begin
      LogSession.Add(DateTimeToStr(now)+' - Close FoxbirdBackup');
      LogSession.Add(' ');
      LogSession.SaveToFile(AppdataPath+'log.txt');
    end;
end;

// Enumération des profils
// La version 2 des profils a changé, depuis FF 67 donc en tenir compte

function TFoxBirdBack.ListProfiles(app: TMozApp): boolean;
var
 // InstallIni: TIniFile;
  ProfileIni: TBbInifile;
  i: integer;
  apppath: string;
  ssect, sdefpath, spath, sname: string;
  Sections: TStringList;
begin
  LBS.Clear;
  Profiles:= Default(TProfiles);
  if app= ff then apppath:= ffpath else apppath:= tbpath;
  if FileExists(apppath+'profiles.ini') then
  begin
    result:= false;
    // detect if it is an unicode 16 with BOM
    ProfileIni:= TBbInifile.Create(apppath+'profiles.ini');
    StartWithLastProfile:= ProfileIni.ReadInteger('General','StartWithLastProfile', 1);
    ProfileVersion:= ProfileIni.ReadInteger('General','Version', 1);
    // Enumerate sections
    Sections:= TStringList.Create;
    ProfileIni.CaseSensitive:= False;   // To be replaced by options but don't work
    ProfileIni.ReadSections(Sections);
    ProfilesCount:= 0;
    CurrentProfile:= 0;

    if Sections.Count > 0 then
    begin
      LogSession.add(DateTimeToStr(now)+' - '+AppToBack+' profiles list:');
      // First, search Install... section if exists (new profiles version)
      for i:= 0 to Sections.Count-1 do
      begin
        ssect:= Sections[i];
        if UpperCase(copy(ssect, 0, 7))='INSTALL' then
        begin
          sdefpath:= ProfileIni.ReadString (ssect, 'Default', '');
          ProfileVersion:= 2;
          Break;
        end else
        begin
          sdefpath:= '';
          ProfileVersion:= 1;
        end;
      end;
      // Now parse profiles
      for i:= 0 to Sections.Count-1 do
      begin
        ssect:= Sections[i];
        if copy(ssect, 0, 7)='Profile' then
        begin
          Inc(ProfilesCount);
          SetLength(Profiles, ProfilesCount);
          Profiles[ProfilesCount-1].Number:= StrToInt(copy(ssect,8,2));   // Is it useful ?
          sname:= IsAnsi2Utf8(ProfileIni.ReadString (ssect, 'Name', ''));
          Profiles[ProfilesCount-1].Name:= sname;
          LBS.Items.Add(sname);
          spath:= IsAnsi2Utf8(ProfileIni.ReadString (ssect, 'Path', ''));
          // New profiles.ini version
          if (ProfileVersion=2) and (sdefpath=spath) then CurrentProfile:= ProfilesCount-1 ;
          spath:= StringReplace(spath, '/', PathDelim, [rfReplaceAll]);
          Profiles[ProfilesCount-1].IsRelative:= Boolean(ProfileIni.ReadInteger(ssect, 'IsRelative', 0));
          if Profiles[ProfilesCount-1].IsRelative then
          begin
            Profiles[ProfilesCount-1].Path:= apppath+spath+PathDelim;
            CurProfilePath:= apppath+IsAnsi2Utf8(spath+PathDelim);
          end else
          begin
            Profiles[ProfilesCount-1].Path:= spath+PathDelim;
            CurProfilePath:= spath+PathDelim;
          end;
          Profiles[ProfilesCount-1].Default:= Boolean(ProfileIni.ReadInteger(ssect, 'Default', 0));
          Profiles[ProfilesCount-1].PType:= app;
          LogSession.add(DateTimeToStr(now)+' - '+AppToBack+' '+Profiles[ProfilesCount-1].Name+': '+Profiles[ProfilesCount-1].Path);
          // Old profiles.ini version
          if (ProfileVersion=1) and (Profiles[ProfilesCount-1].Default) then CurrentProfile:= ProfilesCount-1 ;
        end;
      end;
    end;
    Sections.Free;
    ProfileIni.free;
        If ProfilesCount > 0 then
    begin
      LogSession.add(DateTimeToStr(now)+' - '+AppToBack+' current profile: '+Profiles[CurrentProfile].Name);
      LBS.ItemIndex:= CurrentProfile;
      Result:= True;
    end;
  end;
  LBClick (LBS);

end;

// tri d'un array de records sur champ numérique

procedure TFoxBirdBack.SortArray(var Backs: TBackups;  stype : TSortType);
  var
    i: Integer;
    temp: TBackup;
    chnged: Boolean;
    sorting: boolean;
  begin
    chnged := True;
    while chnged do
    begin
      chnged := False;
      for i := Low(Backs) to High(Backs)-1 do
      begin
        // sort ascending or descending
        if stype= up then sorting:= (Backs[i].Date > Backs[i+1].Date)
        else sorting:= (Backs[i].Date < Backs[i+1].Date);
        if  sorting then
        begin
          temp := Backs[i+1];
          Backs[i+1] := Backs[i];
          Backs[i] := temp;
          chnged := True;
        end;
      end;
    end;
end;

// Enumeration des sauvegardes

function TFoxBirdBack.ListBackups(app: TMozApp): boolean;
var
  backpath: string;
  Comment: TstringList;
  sr:TSearchRec;
  sdate: TDateTime;
  sname: string;
  spath: string;
  BackupsCount: Integer;
  FrmDate: TFormatSettings;
  i: integer;
  bktype: string;
  UZip: TUnZipper;
begin
  LBR.Clear;
  FrmDate.DateSeparator:= '/';
  FrmDate.ShortDateFormat:= 'yyyy'+FrmDate.DateSeparator+'mm'+FrmDate.DateSeparator+'dd';
  FrmDate.TimeSeparator:= ':';
  FrmDate.ShortTimeFormat:= 'hh'+FrmDate.TimeSeparator+'nn'+FrmDate.TimeSeparator+'ss';
  if app= ff then backpath:= FireBack else backpath:= ThunderBack;
  Comment:= TStringList.Create;
  UZip:= TUnZipper.Create;
  BackupsCount:= 0;
  if FindFirst(backpath+ '*.zip',faAnyFile,sr)=0 then
  begin
    repeat
      Comment.Clear;
      try
        UZip.FileName:= backpath+sr.Name;
        UZip.Examine;
        Comment.Text:= UZip.FileComment;
        sname:= IsAnsi2Utf8(Comment.Strings[0]);
        sdate:= StrToDateTime(Comment.Strings[1], FrmDate);
        spath:= IsAnsi2Utf8(Comment.Strings[2]);
        bktype:= Comment.Strings[3];
      except
        sname:= '';
        sdate:= 0;
        spath:= '';
        bktype:= 'no';
      end;
      if ((bktype='ff') and (app=ff)) or ((bktype='tb') and (app=tb)) and (sdate > 0) then
      begin
        Inc(BackupsCount);
        SetLength(Backups, BackupsCount);
        Backups[BackupsCount-1].FileName:= backpath+sr.Name;
        Backups[BackupsCount-1].FileSize:= sr.Size;
        Backups[BackupsCount-1].Profile.Name:= sname;
        Backups[BackupsCount-1].Date:= sdate;
        Backups[BackupsCount-1].Profile.Path:= spath;
        Backups[BackupsCount-1].BType:= app;
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  if BackupsCount > 0 then
  begin
    LogSession.add(DateTimeToStr(now)+' - '+AppToBack+' backup list:');
    SortArray(Backups, up);
    For i:=0 to BackupsCount-1 do
    begin
      LBR.Items.Add(Backups[i].Profile.Name+' : ' +DateTimeToStr(Backups[i].Date));
      LogSession.Add(DateTimeToStr(now)+' - '+AppToBack+' backup '+IntToStr(i)+': '+
                     Backups[i].Profile.Name+' profile: '+ExtractFileName(Backups[i].FileName));
    end;
    LBR.ItemIndex:= 0;
    LastBackup:= ExtractFileName(Backups[BackupsCount-1].FileName);
    LastBackupDate:= Backups[BackupsCount-1].Date;
    LBClick(LBR);
    Result:= True;
 end;
 UZip.Free;
 Comment.Free;
end;

procedure TFoxBirdBack.LBClick(Sender: TObject);
begin
  if TlistBox(Sender).Name = 'LBS' then
  begin
    if (LBS.ItemIndex>=0) and (length(Profiles)>0)  then
    begin
      EProfilePath.Text:= Profiles[LBS.ItemIndex].Path;
      BtnBack.Enabled:= True;
      if LBS.ItemIndex = CurrentProfile
      then LBS.Items[LBS.ItemIndex]:= Format(default_profile_caption, [Profiles[LBS.ItemIndex].Name]);
    end else
    begin
      EProfilePath.Text:= '';
      BtnBack.Enabled:= False;
    end;
  end else
  begin
    if (LBR.ItemIndex>=0) and (length(Backups)>0)  then
    begin
      ERestPath.Text:= Backups[LBR.ItemIndex].Profile.Path;
      EProfileName.Text:= Backups[LBR.ItemIndex].Profile.Name;
      EBkDate.Text:= DateTimeToStr(Backups[LBR.ItemIndex].Date);
      BtnBack.Enabled:= True;
      ELastBackup.text:= LastBackup;
      try
        ELastBkDate.text:= DateTimeToStr(LastBackupDate);
      except
      end;
    end else
    begin
      ERestPath.Text:= '';
      EProfileName.Text:= '';
      EBkDate.Text:= '';
      BtnBack.Enabled:= False;
    end;
  end;
end;

procedure TFoxBirdBack.MenuItem1Click(Sender: TObject);
begin
  if LBR.ItemIndex >= 0 then
  begin
    if MsgDlg(delete_backup_title, Format (delete_backup_caption, [ExtractFileName(Backups[LBR.ItemIndex].FileName)]),
               mtWarning,[mbYes, mbAbort], [btn_yes_caption, btn_abort_caption], 0)= mrYes then
    begin
      if DeleteFile(Backups[LBR.ItemIndex].FileName) then
      begin
        LogSession.add(DateTimeToStr(now)+' - Deleted backup '+Backups[LBR.ItemIndex].FileName);
        ListBackups(ProfileType);
      end else
      begin
         LogSession.add(DateTimeToStr(now)+' - Cannot delete backup '+Backups[LBR.ItemIndex].FileName);
         ShowMessage(Format(cannot_delete_bk_caption, [ExtractFileName(Backups[LBR.ItemIndex].FileName)]));
      end;

    end;
  end;
end;

procedure TFoxBirdBack.PageControl1Change(Sender: TObject);
begin
  If PageControl1.ActivePage=TSBackup then
  begin
    BtnBack.Caption:= btn_backup_caption;
  end else
  begin
    if RBComplete.Checked or RBPartial.Checked then BtnBack.Caption:= btn_restore_caption;
    if RBImport.Checked then BtnBack.Caption:= btn_import_caption;
    if RBExport.Checked then BtnBack.Caption:= btn_export_caption;
  end;
end;

procedure TFoxBirdBack.BtnQuitClick(Sender: TObject);
begin
  Close;
end;

// Change restoration folder
procedure TFoxBirdBack.BtnRestFolderClick(Sender: TObject);
begin
  //ODImpBack.Title:= 'Sélectionner une sauvegarde';                 In Modlangue
  //SDRestorePath.Title:= 'Sélectionner un répertoire';
  if RBImport.Checked then
  begin
    ODImpBack.InitialDir:= UserPath;
    if ODImpBack.Execute then
    begin
      ERestPath.Text:= ODImpBack.FileName;
    end;
    exit;
  end;
  if RBExport.Checked then
  begin
    SDRestorePath.InitialDir:= EBackfolder.Text;
    if SDRestorePath.Execute then ERestPath.Text:= SDRestorePath.FileName+PathDelim;
  end;

end;

function TFoxBirdBack.EnableControls(state: boolean): boolean;
begin
  If PageControl1.ActivePage= TSBackup then TSRestore.Enabled:= state
  else TSBackup.Enabled:= state;
  RBFfox.Enabled:= state;
  RBTbird.Enabled:= state;
  BtnBack.Enabled:= state;
  BtnQuit.Enabled:= state;
  BtnAbout.enabled:= state;
  BtnLog.Enabled:= state;
  ReallyCanClose:= state;
  Result:= state;
  ProgressBar1.Position:= 0;
end;


procedure TFoxBirdBack.BtnBackClick(Sender: TObject);
var
  lockedfile: string;
  zipname: string;
  apppath: string;
  ProfileIni: TBbInifile;
  Relativepath: String;
  x: integer;
  UZip2Imp: TUnzipper;
  Comment: TStringList;
  bktype: string;
begin
  // Check if ff/tb is running
  lockedfile:= Profiles[LBS.ItemIndex].Path+'parent.lock';
  if FileExists(lockedfile) and (not DeleteFile(lockedfile)) then
  begin
    ShowMessage(Format(cannot_save_app_open, [AppToBack])); //AppToBack+CannotSavRest);
    exit;
  end;
  if ProfileType= ff then apppath:= ffpath else apppath:= tbpath;
  // Disable other controls
  EnableControls(False);
  If PageControl1.ActivePage= TSBackup then     // Onglet "sauvegarde" : on lance la compression
  begin
    zipname:= Profiles[LBS.ItemIndex].Name+'_'+FormatDateTime('yyyy_mm_dd_hh_nn_ss',now)+'.zip';
    EbackName.text:= zipname;
    ZipAFolder(Profiles[LBS.ItemIndex].Path, Ebackfolder.text+zipname);
  end else
  begin                        // Onglet Resauration
    if RBImport.Checked then
      begin
        ERestPath.text:= EBackfolder.Text;
        ODImpBack.Filter:= import_filter;
        ODImpBack.InitialDir:= UserPath;
        if ODImpBack.Execute then
        begin
          Comment:= TStringList.create;
          UZip2Imp:= TUnZipper.Create;
          ERestPath.Text:= ODImpBack.FileName;
          try
            UZip2Imp.FileName:= ODImpBack.FileName;
            UZip2Imp.Examine;
            Comment.Text:= UZip2Imp.FileComment;
            bktype:= Comment.Strings[3];

            if ((bktype='ff') and (ProfileType=ff))or  ((bktype='tb') and (ProfileType=tb)) then
            begin
               CopyFile(ODImpBack.FileName, EBackfolder.Text+ExtractFileName(ODImpBack.FileName), True, True);
              ListBackups(ProfileType);
              LogSession.add(DateTimeToStr(now)+' -  Imported "'+ExtractFileName(ODImpBack.FileName)+'" to "'+
                                              EBackfolder.Text );
            end else
            begin
              ShowMessage(Format(cannot_import, [ExtractFileName(ODImpBack.FileName), CRLF ]));
              LogSession.add(DateTimeToStr(now)+' - Wrong backup type');
            end;
          except
             On E :Exception do
              begin
                ShowMessage(Format(cannot_import, [ExtractFileName(ODImpBack.FileName), CRLF ]));
                LogSession.add(DateTimeToStr(now)+' - '+ E.Message);
              end;
          end;
          UZip2Imp.Free;
          Comment.Free;
        end;
      end else
      begin
        if (LBR.ItemIndex >= 0) then
        begin
          if RBComplete.Checked or RBPartial.Checked then
          begin
            RestProfSel.LBS.Items:= LBS.Items;
            RestProfSel.LBS.ItemIndex:= LBS.ItemIndex;
            if RestProfSel.ShowModal= mrOK then
            begin
              ERestPath.Text:= Profiles[RestProfSel.LBS.ItemIndex].Path;
              // Sauvegarde complète : on renomme le dossier du profil courant et on le recrée avec la sauvegarde
              if RBComplete.Checked then
              begin
                If not DirectoryExists(ChompPathDelim(ERestPath.Text)+'_bk') then
                begin
                  if RenameFile(ERestPath.Text, ChompPathDelim(ERestPath.Text)+'_bk'+PathDelim) then
                  begin
                    UnZipFiles(Backups[LBR.ItemIndex].FileName, ERestPath.Text, all);
                    ProfileIni:= TBbInifile.Create(apppath+'profiles.ini');
                    ProfileIni.WriteString ('Profile'+IntToStr(length(Profiles)), 'Name', Profiles[RestProfSel.LBS.ItemIndex].Name+'_bk');
                    ProfileIni.WriteString ('Profile'+IntToStr(length(Profiles)), 'IsRelative', '1');
                    x:= Pos('rofiles', ChompPathDelim(ERestPath.Text)+'_bk');
                    Relativepath:= Copy(ChompPathDelim(ERestPath.Text)+'_bk', x-1, length(ChompPathDelim(ERestPath.Text)));
                    RelativePath:= StringReplace(RelativePath, '\', '/', [rfReplaceAll]);
                    ProfileIni.WriteString ('Profile'+IntToStr(length(Profiles)), 'Path', RelativePath);
                    ProfileIni.free;
                    LogSession.add(DateTimeToStr(now)+' - old profile saved : '+Profiles[RestProfSel.LBS.ItemIndex].Name+'_bk');
                    ListProfiles(ProfileType);
                  end else
                  begin
                    ShowMessage(Format(cannot_restore_profile_locked, [CRLF]));
                    LogSession.add(DateTimeToStr(now)+' - Cannot restore profile '+Profiles[RestProfSel.LBS.ItemIndex].Name);
                  end;
                end else
                begin
                  if DeleteDirectory(ChompPathDelim(ERestPath.Text)+'_bk', false) then
                  begin
                    if RenameFile(ERestPath.Text, ChompPathDelim(ERestPath.Text)+'_bk'+PathDelim) then
                    begin
                      UnZipFiles(Backups[LBR.ItemIndex].FileName, ERestPath.Text, all);
                      LogSession.add(DateTimeToStr(now)+' - old profile saved : '+Profiles[RestProfSel.LBS.ItemIndex].Name+'_bk');
                      ListProfiles(ProfileType);
                    end else
                    begin
                      ShowMessage(Format(cannot_restore_profile_locked, [CRLF]));
                      LogSession.add(DateTimeToStr(now)+' - Cannot restore profile '+Profiles[RestProfSel.LBS.ItemIndex].Name);
                    end;
                  end else
                  begin
                    ShowMessage(Format(cannot_restore_profile_locked, [CRLF]));
                    LogSession.add(DateTimeToStr(now)+' - Cannot restore profile '+Profiles[RestProfSel.LBS.ItemIndex].Name);
;                 end;
                end;
              end;
              // Sauvegarde partielle
              if RBPartial.Checked then
              begin
                UnZipFiles (Backups[LBR.ItemIndex].FileName, ERestPath.Text, partial);
              end;
            end;
          end;
          if RBExport.Checked then
          begin
            SDRestorePath.FileName:= UserPath;
            SDRestorePath.Title:= export_path_caption;
            if SDRestorePath.execute then
            try
              CopyFile(Backups[LBR.ItemIndex].FileName,
                               SDRestorePath.FileName+PathDelim+ExtractFileName(Backups[LBR.ItemIndex].FileName),
                               True, True);
              LogSession.add(DateTimeToStr(now)+' -  Exported "'+ExtractFileName(Backups[LBR.ItemIndex].FileName+'" to "'+
                                               SDRestorePath.FileName+PathDelim));
            except
              On E :Exception do
              begin
                ShowMessage(Format(cannot_export, [ExtractFileName(Backups[LBR.ItemIndex].FileName), CRLF ]));
                LogSession.add(DateTimeToStr(now)+' - '+ E.Message);
              end;
            end;
          end;
        end;
      end;
  end;
  EnableControls(True);
end;

procedure TFoxBirdBack.BtnLogClick(Sender: TObject);
begin
  FLogView.ListBox1.ItemIndex:= -1;
  FLogView.ListBox1.Items.Text := LogSession.Text; ;
  FLogView.showmodal;
end;

procedure TFoxBirdBack.BtnAboutClick(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

function TFoxBirdBack.UnZipFiles(zipname, outpath: string; uType: TUnZipType): boolean;
var
  DefCursor: TCursor;
  TheFileList: TStringList;
  tmplist:TStringList;
  i: integer;
  sname: string;
  pct: Integer;
  logMsg: string;
  UZip: TunZipper;
begin
  result:= True;
  if LBR.ItemIndex >= 0 then
  begin
    DefCursor:= Screen.Cursor;
    Screen.Cursor:=crHourGlass;
    TheFileList:= TStringList.create;
    UZip:= TUnZipper.Create;
    Uzip.FileName:= zipname;
    UZip.OutputPath:= outpath;
    UZip.Examine;
    for i:= 0 to Uzip.Entries.Count-1 do
    begin
      sname:= Uzip.Entries.Entries[i].ArchiveFileName;
      if uTYpe= all then
      begin
        TheFileList.add(sname);
        logMsg:= ' - Restored full backup: ';
      end else
      begin
        if (sname= 'places.sqlite') and CBFav.checked then TheFileList.Add(sname);          // Favoris et historique
        if (sname= 'favicons.sqlite') and CBFav.checked then TheFileList.Add(sname);
        if (sname= 'key4.db') and CBPass.checked then TheFileList.Add(sname);               // Identifiants et passwords
        if (sname= 'logins.json') and CBPass.checked then TheFileList.Add(sname);
        if (sname= 'addons.json') and CBExt.checked then TheFileList.Add(sname);            // Extensions et stockege
        if (sname= 'addonStartup.json.lz4') and CBExt.checked then TheFileList.Add(sname);
        if (pos('extensions/', sname)=1) and CBExt.checked then TheFileList.Add(sname);
        if (pos('storage/', sname)=1) and CBExt.checked then TheFileList.Add(sname);
        if (pos('chrome/', sname)=1) and CBUserStyle.checked then TheFileList.Add(sname);   // Styles utilisateur
        if (sname= 'prefs.js') and CBUserPref.checked then TheFileList.Add(sname);          // Préférences utilisateur
        if (sname= 'content-prefs.sqlite') and CBUserPref.checked then TheFileList.Add(sname);
        if (sname= 'formhistory.sqlite') and CBAutoComp.checked then TheFileList.Add(sname);// Données formulaires
        if (sname= 'cookies.sqlite') and CBCookies.checked then TheFileList.Add(sname);     // Cookies
        if (sname= 'handlers.json') and CBApps.checked then TheFileList.Add(sname);         // Applications par défaut
        if (sname= 'permissions.sqlite') and CBSitePrefs.checked then TheFileList.Add(sname);   // Permissions
        if (sname= 'search.json.mozlz4') and CBSearch.checked then TheFileList.Add(sname);  // moteurs de recherche
        if (sname= 'cert9.db') and CBCertif.checked then TheFileList.Add(sname);            // Certificats
        if (pos('abook', sname)=1) and (CBAddress.checked) and (RBTbird.checked) then TheFileList.Add(sname); //TB Address books
        logMsg:= ' - Restored partial backup: ';
      end;
    end;
    Zcount:= TheFileList.Count;
    progres:= 0;
    if Zcount > 0 then
    begin
      tmplist:= TStringList.Create;
      for i:= 0 to Zcount-1 do
      begin
        try
          tmplist.clear;
          tmplist.text:= TheFileList.Strings[i];
          UZip.UnZipFiles(zipname, tmplist);
        except
          On E :Exception do LogSession.add(DateTimeToStr(now)+' - '+ E.Message);
        end;
        pct:= (i*100) div Zcount;
        if pct > progres then
        begin
          progres:= pct;
          ProgressBar1.Position:= pct;
        end;
      end;
      tmplist.free;
    end;
    LogSession.add(DateTimeToStr(now)+logMsg+ ZipName);
    UZip.free;
    TheFileList.free;
    Screen.Cursor:= DefCursor;
  end;
end;




procedure TFoxbirdBack.OnArchiveProgress(
  Sender: TObject; Progress: Byte; var Abort: Boolean);
begin
  ProgressBar1.Position := Progress;
end;

Procedure TFoxbirdBack.ZipperProgress(Sender : TObject; Const Pct : Double);
begin
  Application.ProcessMessages;
end;

Procedure TFoxbirdBack.ZipperEndFile(Sender : TObject; Const Ratio : Double) ;
begin
  inc(progres);
  ProgressBar1.Position:= (progres*100) div Zcount ;
end;

function TFoxBirdBack.ZipAFolder(Folder, ZipName: string): boolean;
var
  Comment: TStringList;
  FrmDate: TFormatSettings;
  DefCursor:TCursor;
  AZipper: TZipper;
  Zentries: TZipFileEntries;
  szPathEntry: string;
   TheFileList:TstringList;
   i: integer;
   Fentry: string;
begin
Result:= True;
  FrmDate.DateSeparator:= '/';
  FrmDate.ShortDateFormat:= 'yyyy'+FrmDate.DateSeparator+'mm'+FrmDate.DateSeparator+'dd';
  FrmDate.TimeSeparator:= ':';
  FrmDate.ShortTimeFormat:= 'hh'+FrmDate.TimeSeparator+'nn'+FrmDate.TimeSeparator+'ss';
  Comment:= TStringList.Create;
  AZipper := TZipper.Create;
  AZipper.OnEndFile := @ZipperEndFile;
  AZipper.OnProgress:= @ZipperProgress;
  AZipper.Clear;
  ZEntries := TZipFileEntries.Create(TZipFileEntry);
  AZipper.Filename := ZipName;
  Comment.Add(IsUtf82Ansi(Profiles[LBS.ItemIndex].Name));
  Comment.Add(FormatDateTime('yyyy/mm/dd hh:nn:ss',now, FrmDate));
  Comment.Add(IsUtf82Ansi(Profiles[LBS.ItemIndex].Path));
  Comment.Add(ProfileString[ord(ProfileType)]);
  AZipper.FileComment:= Comment.Text;
   // Verify valid directory
  If DirectoryExists(Folder) then
  begin
    DefCursor:= Screen.Cursor;
    Screen.Cursor:=crHourGlass;
    szPathEntry:= Folder;
    TheFileList:=TstringList.Create;
    try
      FindAllFiles(TheFileList, Folder);
      for i:=0 to TheFileList.Count -1 do
      begin
        // Make sure the RelativeDirectory files are not in the root of the ZipFile
        FEntry:= CreateRelativePath(TheFileList[i],szPathEntry);
        // Dont Zip absolute path info
        if copy(Fentry, 0, 2) <> Copy(TheFileList[i],0, 2) then
        ZEntries.AddFileEntry(TheFileList[i],FEntry);
      end;
    finally
      TheFileList.Free;
    end;
    if (ZEntries.Count > 0) then
    begin
      // To animate the progress bar
      Zcount:= ZEntries.Count;
      progres:= 0;
      try
        AZipper.ZipFiles(ZEntries);
        LogSession.add(DateTimeToStr(now)+' - Created backup: '+ ZipName);
      except
        On E :Exception do
        begin
           LogSession.add(DateTimeToStr(now)+' - '+E.Message);
        end;
      end;
    end;
    Screen.Cursor:= DefCursor;
  end;
  ZEntries.Free;
  AZipper.Free;
 // Zip.free;
  Comment.Free;
  ListBackups(ProfileType);
end;

procedure TFoxBirdBack.RBBirdFoxClick(Sender: TObject);
var
  iconid: string;
begin
  if RBFfox.checked then
  begin
    AppToBack:= 'Firefox';
    iconid:= 'iffox';
    EBackfolder.Text:= FireBack;
    ProfileType:= ff;

  end else
  begin
    AppToBack:= 'Thunderbird';
    iconid:= 'itbird';
    EBackfolder.Text:= ThunderBack;
    ProfileType:= tb;
  end;


  CBAddress.Visible:= RBTbird.Checked;
  ListProfiles(ProfileType);
  ListBackups(ProfileType);
  Caption:= Format(caption_prefix, [AppToBack]);
  Application.Icon.LoadFromResourceName(HInstance, iconid);
  ImgBack.Picture.Icon.LoadFromResourceName(HInstance,iconid);
  AboutBox.Image1.Picture.Icon.LoadFromResourceName(HInstance, iconid);
end;



function TFoxBirdBack.EnableRestItems(state: boolean): boolean;
begin
  CBFav.Enabled:= state;
  CBPass.Enabled:= state;
  CBExt.Enabled:= state;
  CBUserPref.Enabled:= state;
  CBUserStyle.Enabled:= state;
  CBAutoComp.Enabled:= state;
  CBCookies.Enabled:= state;
  CBApps.Enabled:= state;
  CBSitePrefs.Enabled:= state;
  CBSearch.Enabled:= state;
  CBCertif.Enabled := state;
  CBAddress.Enabled:= state;
  result:= state;
end;

procedure TFoxBirdBack.RBManageClick(Sender: TObject);
begin
  // Restauration complète du profil
  if TRadioButton(Sender).Name = 'RBComplete' then
  begin
    EnableRestItems(False);
    BtnBack.Caption:= btn_restore_caption;
    LRestPath.Caption:= restore_path_caption;
    If LBR.ItemIndex >= 0 then ERestPath.text:= Backups[LBR.ItemIndex].Profile.Path;
  end;
  if TRadioButton(Sender).Name = 'RBPartial' then
  begin
    EnableRestItems(True);
    BtnBack.Caption:= btn_restore_caption;
    LRestPath.Caption:= restore_path_caption;
    If LBR.ItemIndex >= 0 then ERestPath.text:= Backups[LBR.ItemIndex].Profile.Path;
  end;
  if TRadioButton(Sender).Name = 'RBImport' then
  begin
    EnableRestItems(False);
    BtnBack.Caption:= btn_import_caption;
    LRestPath.Caption:= backup_name_to_import;
    ERestPath.text:= '';
  end;
  if TRadioButton(Sender).Name = 'RBExport' then
  begin
    EnableRestItems(False);
    BtnBack.Caption:= btn_export_caption;
    LRestPath.Caption:= export_path_caption;
    //ERestPath.text:= '';
  end;
end;

// Read language file items
procedure TFoxBirdBack.ModLangue ;
begin
  With LangFile do
  begin
    caption_prefix:= ReadString(LangStr, 'caption_prefix', 'Sauvegarde de profil %s');
    Aboutbox.Caption:= ReadString(LangStr, 'Aboutbox.Caption', 'A propos de FoxBirdBackup');
    AboutBox.LUpdate.Caption:= ReadString(LangStr, 'AboutBox.LUpdate.Caption', 'Recherche de mise à jour');
    // Diverse strings
    default_profile_caption:= ReadString(LangStr, 'default_profile_caption', '%s (profil par défaut)');
    delete_backup_title:= ReadString(LangStr, 'delete_backup_title', 'Supprimer une sauvegarde');
    delete_backup_caption:= ReadString(LangStr, 'delete_backup_caption', 'Voulez-vous supprimer la sauvegarde "%s" ?');
    cannot_delete_bk_caption:=  ReadString(LangStr, 'cannot_delete_bk_caption', 'Impossible de supprimer le fichier "%s".');
    btn_yes_caption:= ReadString(LangStr, 'btn_yes_caption', 'Oui');
    btn_no_caption:= ReadString(LangStr, 'btn_no_caption', 'Non');
    btn_abort_caption:= ReadString(LangStr, 'btn_abort_caption', 'Abandon');
    btn_cancel_caption:= ReadString(LangStr, 'btn_cancel_caption', 'Annuler');
    btn_backup_caption:= ReadString(LangStr, 'btn_backup_caption', 'Sauvegarder');
    btn_restore_caption:= ReadString(LangStr, 'btn_restore_caption', 'Restaurer');
    btn_import_caption:= ReadString(LangStr, 'btn_import_caption', 'Importer');
    btn_export_caption:= ReadString(LangStr, 'btn_export_caption', 'Exporter');
    cannot_export:= ReadString(LangStr, 'cannot_export', 'Exportation de "%s" impossible,%svoir le fichier log pour plus de détails');
    cannot_import:= ReadString(LangStr, 'cannot import', 'Importation de "%s" impossible,%svoir le fichier log pour plus de détails');
    ODImpBack.Title:= ReadString(LangStr, 'ODImpBack.Title',ODImpBack.Title);
    SDRestorePath.Title:= ReadString(LangStr, 'SDRestorePath.Title', SDRestorePath.Title);
    cannot_save_app_open:= ReadString(LangStr, 'cannot_save_app_open', '%s est ouvert, opération impossible') ;
    cannot_restore_profile_locked:= ReadString(LangStr, 'cannot_restore_profile_locked',
                                               'Impossible de restaurer la sauvegarde %s Profil verrouillé ou inacessible');
    restore_path_caption:= ReadString(LangStr, 'restore_path_caption', 'Chemin de restauration');
    export_path_caption:=  ReadString(LangStr, 'export_path_caption', 'Chemin d''exportation');
    import_filter:= ReadString(LangStr, 'import_filter', 'Fichiers ZIP|*.zip');
    backup_name_to_import:= ReadString(LangStr, 'backup_name_to_import', 'Sauvegarde à importer');
    // Backup tab
    TSBackup.Caption:= ReadString(LangStr, 'TSBackup.Caption', TSBackup.Caption);
    LPath.Caption:= ReadString(LangStr, 'LPath.Caption', LPath.Caption);
    LBackFolder.Caption:= ReadString(LangStr, 'LBackFolder.Caption', LBackFolder.Caption);
    LBackName.Caption:= ReadString(LangStr, 'LBackName.Caption', LBackName.Caption);
    LLastBackup.Caption:= ReadString(LangStr, 'LLastBackup.Caption', LLastBackup.Caption);
    LLastBkDate.Caption:= ReadString(LangStr, 'LLastBkDate.Caption', LLastBkDate.Caption);
    BtnBack.Caption:= ReadString(LangStr, 'BtnBack.Caption', BtnBack.Caption);
    BtnQuit.Caption:= ReadString(LangStr, 'BtnQuit.Caption', BtnQuit.Caption);
    BtnAbout.Caption:= ReadString(LangStr, 'BtnAbout.Caption', BtnAbout.Caption);
    // Restore tab
    TSRestore.Caption:= ReadString(LangStr, 'TSRestore.Caption', TSRestore.Caption);
    LRestPath.caption:= restore_path_caption;
    LProfName.Caption:= ReadString(LangStr, 'LProfName.Caption', LProfName.Caption);
    LBackupDate.Caption:= ReadString(LangStr, 'LBackupDate.Caption', LBackupDate.Caption);
    GroupBox1.Caption:= ReadString(LangStr, 'GroupBox1.Caption', GroupBox1.Caption);
    RBComplete.Caption:= ReadString(LangStr, 'RBComplete.Caption', RBComplete.Caption);
    RBPartial.Caption:= ReadString(LangStr, 'RBPartial.Caption', RBPartial.Caption);
    RBExport.Caption:= ReadString(LangStr, 'RBExport.Caption', RBExport.Caption);
    RBImport.Caption:= ReadString(LangStr, 'RBImport.Caption', RBImport.Caption);
    CBFav.Caption:= ReadString(LangStr, 'CBFav.Caption', CBFav.Caption);
    CBPass.Caption:= ReadString(LangStr, 'CBPass.Caption', CBPass.Caption);
    CBAutoComp.Caption:= ReadString(LangStr, 'CBAutoComp.Caption', CBAutoComp.Caption);
    CBUserStyle.Caption:= ReadString(LangStr, 'CBUserStyle.Caption', CBUserStyle.Caption);
    CBCookies.Caption:= ReadString(LangStr, 'CBCookies.Caption', CBCookies.Caption);
    CBSearch.Caption:= ReadString(LangStr, 'CBSearch.Caption', CBSearch.Caption);
    CBApps.Caption:= ReadString(LangStr, 'CBApps.Caption', CBApps.Caption);
    CBSitePrefs.Caption:= ReadString(LangStr, 'CBSitePrefs.Caption', CBSitePrefs.Caption);
    CBCertif.Caption:= ReadString(LangStr, 'CBCertif.Caption', CBCertif.Caption);
    CBExt.Caption:= ReadString(LangStr, 'CBExt.Caption', CBExt.Caption);
    CBUserPref.Caption:= ReadString(LangStr, 'CBUserPref.Caption', CBUserPref.Caption);
    CBAddress.Caption:= ReadString(LangStr, 'CBAddress.Caption', CBAddress.Caption);
    // Selection du profil
    RestProfSel.Caption:= ReadString(LangStr, 'RestProfSel.Caption', RestProfSel.Caption);
    RestProfSel.BtnCancel.Caption:= btn_cancel_caption;
    // Fenêtre log
    FLogView.Caption:= ReadString(LangStr, 'FLogView.Caption', FLogView.Caption);
    FLogView.LSelLines.Caption:= ReadString( LangStr, 'FLogView.LSelLines.Caption', FLogView.LSelLines.Caption);
    FLogView.BtnQuit.Caption:= BtnQuit.Caption;
    FLogView.BtnPrint.Caption:= ReadString( LangStr, 'FLogView.BtnPrint.Caption', FLogView.BtnPrint.Caption);
  end;
end;

end.

