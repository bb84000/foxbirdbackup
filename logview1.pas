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
  txtheight: Integer;
  linespacing: integer;
  Lmargin, TMargin: Integer;
  Bmarginpos: Integer;
  XPos, YPos: integer;
  scaleFactor: double;
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
    Printer.Canvas.Font.Size := 8;
    scaleFactor:=Printer.YDPI / Screen.PixelsPerInch;
    txtheight:= Printer.Canvas.TextHeight('Text Height');
    FlogView.Canvas.Font.Size := 8;
    txtheight:= trunc(txtheight*scalefactor);
    TMargin:= Printer.YDPI div 3; // 1/3 inch
    LMargin:= Printer.XDPI div 3; // 1/3 inch
    BMarginpos:= Printer.PageHeight - TMargin;
    linespacing:= txtheight;
    Xpos:= LMargin;
    Ypos:= TMargin;
    Printer.BeginDoc;
    for i:= 0 to ListBox1.count -1 do
    begin
      if PrintDialog1.PrintRange= prSelection then
      begin
        if listbox1.selected[i]  then
        begin
           Printer.Canvas.TextOut(Xpos, YPos, ListBox1.Items.Strings[i]);
           Ypos:= Ypos+Linespacing;
        end ;
      end else
      begin
        Printer.Canvas.TextOut(Xpos, Ypos, ListBox1.Items.Strings[i]);
        Ypos:= Ypos+Linespacing;
      end;
      if Ypos > BMarginpos then
      begin
        Ypos:= Tmargin;
        Printer.NewPage;
       end;
     end;
    Printer.EndDoc;
  end
end;

end.

