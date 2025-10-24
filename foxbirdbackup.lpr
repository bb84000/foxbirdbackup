program FoxBirdBackup;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, printer4lazarus, FoxBirdBackup1, restprofsel1,
  logview1, lazbbinifiles
  { you can add units after this };

{$R *.res}
{$R foxbirdicons.rc}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFoxBirdBack, FoxBirdBack);
  Application.CreateForm(TRestProfSel, RestProfSel);
  Application.CreateForm(TFLogView, FLogView);                
  //moved to form creation routine
  Application.Run;
end.

