unit uConsoleLog;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  uLog;

type
	TConsoleLog = class(TLog)
  public
    procedure Add(const AVerb: TVerbosity; const AMsg: string); override;
  end;

implementation

procedure TConsoleLog.Add(const AVerb: TVerbosity; const AMsg: string);
begin
	if FVerb >= AVerb then
	  WriteLn(Format('%s: %s', [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;

end.
