;--------------------------------
; Installation script for FoxBirdBackup
; bb - sdtp - october 2021
;--------------------------------
  Unicode true
  
  !include MUI2.nsh
  ;!include "${NSISDIR}\Contrib\Modern UI\BB.nsh"
  !include x64.nsh
  !include FileFunc.nsh

;--------------------------------
;Configuration

 ;General
  Name "FF/TB Profile backup"
  OutFile "InstFoxBirdBackup.exe"
  !define lazarus_dir "C:\Users\Bernard\Documents\Lazarus"
  !define source_dir "${lazarus_dir}\foxbirdbackup"

  RequestExecutionLevel admin

  ;Windows vista.. 10 manifest
  ManifestSupportedOS all


  !define MUI_ICON "${source_dir}\foxbirdbackup.ico"
  !define MUI_UNICON "${source_dir}\foxbirdbackup.ico"

  ;Folder selection page
  InstallDir "$PROGRAMFILES\foxbirdbackup"
  
  ; Variables to properly manage X64 or X32
  var exe_to_inst       ; "32.exe" or "64.exe"
  var exe_to_del
  var dll_to_inst       ; "32.dll" or "64.dll"
  var dll_to_del
  ;var sysfolder         ; system 32 folder

  ;--------------------------------
; Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Language Selection Dialog Settings

  ;Remember the installer language
  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
  !define MUI_LANGDLL_REGISTRY_KEY "Software\SDTP\foxbirdbackup"
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"
  !define MUI_FINISHPAGE_SHOWREADME
  !define MUI_FINISHPAGE_SHOWREADME_TEXT "$(Check_box)"
  !define MUI_FINISHPAGE_SHOWREADME_FUNCTION inst_shortcut
  !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
;-----------------------------
;Pages


  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE $(licence)
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "French"

  ;Licence langage file
  LicenseLangString Licence ${LANG_ENGLISH} "${source_dir}\license.txt"
  LicenseLangString Licence ${LANG_FRENCH}  "${source_dir}\licensf.txt"
  
    ;Language strings for program name
  LangString ProgNameStr ${LANG_ENGLISH}  "FoxBirdBackup"
  LangString ProgNameStr ${LANG_FRENCH} "FoxBirdBackup"

  ;Language strings for uninstall string
  LangString RemoveStr ${LANG_ENGLISH}  "FoxBirdBackup"
  LangString RemoveStr ${LANG_FRENCH} "FoxBirdBackup"

  ;Language string for links
  LangString UninstLnkStr ${LANG_ENGLISH} "FoxBirdBackup uninstall.lnk"
  LangString UninstLnkStr ${LANG_FRENCH} "Désinstallation de FoxBirdBackup.lnk"

  LangString UnPrevStr ${LANG_ENGLISH} "A previous FoxBirdBackup version is installed. $\n$\nClick 'OK' to remove it \
  or 'Cancel' to cancel this upgrade."
  LangString UnPrevStr ${LANG_FRENCH} "Une précédente version de FoxBirdBackup est installée. $\n$\nCliquez sur 'OK' pour la supprimer \
  ou 'Annuler' pour annuler cette mise à jour."

  ;Language strings for language selection dialog
  LangString LangDialog_Title ${LANG_ENGLISH} "Installer Language|$(^CancelBtn)"
  LangString LangDialog_Title ${LANG_FRENCH} "Langue d'installation|$(^CancelBtn)"

  LangString LangDialog_Text ${LANG_ENGLISH} "Please select the installer language."
  LangString LangDialog_Text ${LANG_FRENCH} "Choisissez la langue du programme d'installation."

  ;language strings for checkbox
  LangString Check_box ${LANG_ENGLISH} "Install a shortcut on the desktop"
  LangString Check_box ${LANG_FRENCH} "Installer un raccourci sur le bureau"

;--------------------------------

!getdllversion  "${source_dir}\foxbirdbackupwin64.exe" expv_
!define FileVersion "${expv_1}.${expv_2}.${expv_3}.${expv_4}"

  VIProductVersion "${FileVersion}"
  VIAddVersionKey "FileVersion" "${FileVersion}"
  VIAddVersionKey "ProductName" "$OutFile"
  VIAddVersionKey "FileDescription" "FoxBirdBackup Installer"
  VIAddVersionKey "LegalCopyright" "sdtp - bb"
  VIAddVersionKey "ProductVersion" "${FileVersion}"

  ; Change nsis brand line
  BrandingText "$(ProgNameStr) version ${FileVersion} - bb - sdtp"

; The stuff to install

Section "Dummy Section" SecDummy
  SetShellVarContext all
  SetOutPath "$INSTDIR"

  ${If} ${RunningX64}
    SetRegView 64    ; change registry entries and install dir for 64 bit
  ${EndIf}

  ;Copy all files, files whhich have the same name in 32 and 64 bit are copied
  ; with 64 or 32 in their name, the renamed
  
  File  "${source_dir}\foxbirdbackupwin64.exe"
  File  "${source_dir}\foxbirdbackupwin32.exe"
  
    ${If} ${RunningX64}  ; change registry entries and install dir for 64 bit
     StrCpy $exe_to_inst "64.exe"
     StrCpy $dll_to_inst "64.dll"
     StrCpy $exe_to_del "32.exe"
     StrCpy $dll_to_del "32.dll"
     ;StrCpy $sysfolder "$WINDIR\sysnative"
  ${Else}
     StrCpy $exe_to_inst "32.exe"
     StrCpy $dll_to_inst "32.dll"
     StrCpy $exe_to_del "64.exe"
     StrCpy $dll_to_del "64.dll"
     ;StrCpy $sysfolder "$WINDIR\system32"
  ${EndIf}

  SetOutPath "$INSTDIR"
  ; Delete old files if they exist as we can not rename if the file exists
  Delete /REBOOTOK "$INSTDIR\foxbirdbackup.exe"
  
  ; Rename 32 or 64 files
  Rename /REBOOTOK "$INSTDIR\foxbirdbackupwin$exe_to_inst" "$INSTDIR\foxbirdbackup.exe"

  ; delete non used files
  Delete "$INSTDIR\foxbirdbackupwin$exe_to_del"

  ; Install other files
  File "${source_dir}\licensf.txt"
  File "${source_dir}\license.txt"
  File "${source_dir}\history.txt"
  File "${source_dir}\foxbirdbackup.txt"
  File "${source_dir}\foxbirdbackup.lng"

  ; write out uninstaller
  WriteUninstaller "$INSTDIR\uninst.exe"
  
  ; Get install folder size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  
  ;Write uninstall in register
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "DisplayIcon" "$INSTDIR\uninst.exe"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "DisplayName" "$(RemoveStr)"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "DisplayVersion" "${expv_1}.${expv_2}.${expv_3}.${expv_4}"
  WriteRegDWORD HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "EstimatedSize" "$0"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "Publisher" "SDTP"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "URLInfoAbout" "www.sdtp.com"
  WriteRegStr HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup" "HelpLink" "www.sdtp.com"
  ;Store install folder
  WriteRegStr HKCU "Software\SDTP\foxbirdbackup" "InstallDir" $INSTDIR
SectionEnd ; end of default section


; Install shortcuts, language dependant

Section "Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\foxbirdbackup"
  CreateShortCut  "$SMPROGRAMS\foxbirdbackup\FoxBirdBackup.lnk" "$INSTDIR\foxbirdbackup.exe" "" "$INSTDIR\foxbirdbackup.exe" 0
  CreateShortCut  "$SMPROGRAMS\foxbirdbackup\$(UninstLnkStr)" "$INSTDIR\uninst.exe" "" "$INSTDIR\uninst.exe" 0
 
SectionEnd

;Uninstaller Section

Section Uninstall
  SetShellVarContext all
; ON ferme l'application avant de la désinstaller

; add delete commands to delete whatever files/registry keys/etc you installed here.
Delete "$INSTDIR\history.txt"
Delete "$INSTDIR\foxbirdbackup.txt"
Delete "$INSTDIR\foxbirdbackup.lng"
Delete /REBOOTOK "$INSTDIR\foxbirdbackup.exe"
Delete "$INSTDIR\uninst.exe"

; remove shortcuts, if any.
  Delete  "$SMPROGRAMS\foxbirdbackup\FoxBirdBackup.lnk"
  Delete  "$DESKTOP\foxbirdbackup.lnk"
  Delete "$SMPROGRAMS\foxbirdbackup\$(UninstLnkStr)"


; remove directories used.
  RMDir "$SMPROGRAMS\foxbirdbackup"
  RMDir "$INSTDIR"

DeleteRegKey HKCU "Software\SDTP\foxbirdbackup"
DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\foxbirdbackup"
;DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "FoxBirdBackup"

SectionEnd ; end of uninstall section


Function .onInit
  ${If} ${RunningX64}  ; change registry entries and install dir for 64 bit
    SetRegView 64
    StrCpy "$INSTDIR" "$PROGRAMFILES64\foxbirdbackup"
  ${Else}

  ${EndIf}
    ; Close all apps instance
  FindProcDLL::FindProc "$INSTDIR\foxbirdbackup.exe"
  ${While} $R0 > 0
    FindProcDLL::KillProc "$INSTDIR\foxbirdbackup.exe"
    FindProcDLL::WaitProcEnd "$INSTDIR\foxbirdbackup.exe" -1
    FindProcDLL::FindProc "$INSTDIR\foxbirdbackup.exe"
  ${EndWhile}
FunctionEnd



Function inst_shortcut
  CreateShortCut "$DESKTOP\foxbirdbackup.lnk" "$INSTDIR\foxbirdbackup.exe"
FunctionEnd

