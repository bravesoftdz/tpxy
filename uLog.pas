unit uLog;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes;

type
	TVerbosity = (vNone, vNormal, vVerbose, vVery);

type
	TLog = class(TComponent)
  protected
  	FVerb: TVerbosity;
  public
  	constructor Create(Owner: TComponent); override;
    procedure Add(const AVerb: TVerbosity; const AMsg: string); virtual; abstract;
  published
		property Verb: TVerbosity read FVerb write FVerb default vNormal;
  end;

implementation

constructor TLog.Create(Owner: TComponent);
begin
  inherited;
  FVerb := vNormal;
end;

end.
