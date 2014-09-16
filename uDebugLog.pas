unit uDebugLog;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  uLog;

type
	TDebugLog = class(TLog)
  public
    procedure Add(const AVerb: TVerbosity; const AMsg: string); override;
  end;

implementation

procedure TDebugLog.Add(const AVerb: TVerbosity; const AMsg: string);
begin
	if FVerb >= AVerb then
  	OutputDebugString(PChar(Format('%s: %s', [FormatDateTime('hh:nn:ss', Now), AMsg])));
end;

end.
