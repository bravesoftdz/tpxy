unit uThrottleRule;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Masks;

type
	TThrottleRule = class(TCollectionItem)
  private
  	FPattern: string;
    FRecv: Integer;
    FSend: Integer;
  published
    property Pattern: string read FPattern write FPattern;
    property Recv: Integer read FRecv write FRecv;
    property Send: Integer read FSend write FSend;
  end;

	TThrottelRulesCollection = class(TOwnedCollection)
  public
  	function Find(const AHost: string; const APort: Word): TThrottleRule;
    function AddRule(const APattern: string; const ARecv, ASend: Integer): TThrottleRule;
  end;

implementation

{ TThrottleRule }

{ TThrottelRulesCollection }

function TThrottelRulesCollection.Find(const AHost: string; const APort: Word): TThrottleRule;
var
	i: integer;
  rule: TThrottleRule; 
  str: string;
begin
	str := Format('%s:%d', [AHost, APort]);
  for i := 0 to Count - 1 do begin
		rule := Items[i] as TThrottleRule;
    if MatchesMask(str, rule.FPattern) then begin
    	Result := rule;
      Exit;    
    end;          
  end;
  Result := nil;
end;

function TThrottelRulesCollection.AddRule(const APattern: string; const ARecv, ASend: Integer): TThrottleRule;
begin
  Result := inherited Add as TThrottleRule;
  Result.FPattern := APattern;
  Result.FRecv := ARecv;
  Result.FSend := ASend;
end;

end.
