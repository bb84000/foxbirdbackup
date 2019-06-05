unit logview1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  PrintersDlgs, Printers;

type

  { TFLogView }

  TFLogView = class(TForm)
    BtnQuit: TButton;
    BtnPrint: TButton;
    LSelLines: TLabel;
    ListBox1: TListBox;
    Panel1: TPanel;
    PnlBtns: TPanel;
    PrintDialog1: TPrintDialog;


    procedure BtnPrintClick(Sender: TObject);
  private

  public

  end;

var
  FLogView: TFLogView;

implementation

{$R *.lfm}

{ TFLogView }

procedure TFLogView.BtnPrintClick(Sender: TObject);
var
  i: integer;
  linescount: integer;
begin
  if listbox1.SelCount > 0 then
  begin
    PrintDialog1.Options:=[poSelection];
    PrintDialog1.PrintRange:= prSelection;
  end else
  begin
    PrintDialog1.Options:=[];
    PrintDialog1.PrintRange:= prAllPages;
  end;
  if PrintDialog1.Execute then
  begin
    Printer.BeginDoc;
    Printer.Canvas.Font.Size := 8;
    linescount:= 0;
    for i:= 0 to ListBox1.count -1 do
    begin
      if PrintDialog1.PrintRange= prSelection then
      begin
        if listbox1.selected[i]  then
        begin
           inc (linescount);
           Printer.Canvas.TextOut(0, trunc(80*linescount), ListBox1.Items.Strings[i]);
        end ;
      end else
      begin
        inc (linescount);
        Printer.Canvas.TextOut(0, trunc(80*linescount), ListBox1.Items.Strings[i]);
      end;
      if linescount > 80 then
      begin
      linescount:= 0;
      Printer.NewPage;

      end;

    end;
    Printer.EndDoc;
  end
end;

end.

