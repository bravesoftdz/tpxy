unit uMemoLog;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, System.Actions, Vcl.ActnList,
  Vcl.Menus, Vcl.StdCtrls,
  uLog;

type
	TMemoLog = class(TLog)
  private
  	FMemo: TMemo;
  public
    procedure Add(const AVerb: TVerbosity; const AMsg: string); override;
  published
    property Memo: TMemo read FMemo write FMemo;
  end;

implementation

procedure TMemoLog.Add(const AVerb: TVerbosity; const AMsg: string);
begin
	if Assigned(FMemo) then begin
    if FVerb >= AVerb then
      FMemo.Lines.Add(Format('%s: %s', [FormatDateTime('hh:nn:ss', Now), AMsg]));
  end;
end;

end.
