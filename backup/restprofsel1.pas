unit restprofsel1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TRestProfSel }

  TRestProfSel = class(TForm)
    BtnOK: TButton;
    BtnCancel: TButton;
    LBS: TListBox;
  private

  public

  end;

var
  RestProfSel: TRestProfSel;

implementation

{$R *.lfm}

end.

