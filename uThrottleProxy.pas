unit uThrottleProxy;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
	IdBaseComponent, IdComponent, IdCustomTCPServer, IdContext,
  IdTCPServer, IdCmdTCPServer, IdHTTPProxyServer, IdSocksServer, IdIOHandler,
  IdIOHandlerStream, IdIntercept, IdInterceptThrottler, uLog;

const
	STAT_COUNT = 10;

type
  TStatItem = record
    Sent: Cardinal;
    Rec: Cardinal;
  end;
  TStat = array[0..STAT_COUNT - 1] of TStatItem;

type
	TThrottleProxy = class(TComponent)
  private
  	FServer: TIdSocksServer;
    FBitsPerSec: Integer;
    FRec, FSent: Cardinal;
    FStartTime: TDateTime;
    FStat: TStat;
    FPort: Word;
    FLog: TLog;
    FResolveHost: boolean;
    function GetActive: boolean;
    procedure SetActive(Value: boolean);
    procedure ResetStat;
    procedure AddLog(const AVerb: TVerbosity; const AMsg: string);
    function GetHostName(const AIP: string): string;

    procedure Server_BeforeSocksConnect(AContext: TIdSocksServerContext;
      var VHost: string; var VPort: Word; var VAllowed: Boolean);
    procedure Server_Connect(AContext: TIdContext);
    procedure Server_Disconnect(AContext: TIdContext);

    procedure Throttle_Connect(ASender: TIdConnectionIntercept);
    procedure Throttle_Disconnect(ASender: TIdConnectionIntercept);
    procedure Throttle_Receive(ASender: TIdConnectionIntercept;
      var ABuffer: TArray<System.Byte>);
    procedure Throttle_Send(ASender: TIdConnectionIntercept;
      var ABuffer: TArray<System.Byte>);

  public
  	constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    procedure AddStat(const ASent, ARec: Cardinal);
    procedure AvgStat(var AStat: TStatItem);
    procedure UpdateStat;

    property Active: boolean read GetActive write SetActive;
  published
  	property BitsPerSec: integer read FBitsPerSec write FBitsPerSec default 0;
    property Port: Word read FPort write FPort default 1080;
    property ResolveHost: boolean read FResolveHost write FResolveHost default false;
    property Log: TLog read FLog write FLog;
  end;

implementation

uses
	DateUtils, Winapi.Winsock2;

{ TThrottleProxy }

constructor TThrottleProxy.Create(Owner: TComponent);
begin
	inherited;
  FServer := nil;
  FPort := 1080;
  FBitsPerSec := 0;
  FResolveHost := false;
end;

destructor TThrottleProxy.Destroy;
begin
  inherited;
end;

procedure TThrottleProxy.UpdateStat;
var
	td: integer;
  sps, spr: integer;
  st: TStatItem;
begin
  td := SecondsBetween(Now, FStartTime);
  if td > 0 then begin
    sps := Trunc(FSent / td) * 8;
    spr := Trunc(FRec / td) * 8;
	  AddStat(sps, spr);
  end;
  AvgStat(st);
  if (td > 10) then
  	ResetStat;
end;

function TThrottleProxy.GetHostName(const AIP: string): string;
var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
  WSAData: TWSAData;
  AnsiIP: AnsiString;
begin
  WSAStartup($101, WSAData);
  AnsiIP := AnsiString(AIP);
  SockAddrIn.sin_addr.s_addr := inet_addr(PAnsiChar(AnsiIP));
  HostEnt := gethostbyaddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
  if HostEnt <> nil then
    Result := string(Hostent^.h_name)
  else
    Result := AIP;
  WSACleanup;
  if Result = '' then
  	Result := AIP;
end;

procedure TThrottleProxy.AddLog(const AVerb: TVerbosity; const AMsg: string);
begin
  if Assigned(FLog) then
  	Flog.Add(AVerb, AMsg);
end;

procedure TThrottleProxy.ResetStat;
begin
  FRec := 0;
  FSent := 0;
  FStartTime := Now;
end;

procedure TThrottleProxy.AvgStat(var AStat: TStatItem);
var
	i: integer;
  ssum, srec, cnt: Cardinal;
begin
	cnt := 0;
  ssum := 0;
  srec := 0;
	for i := 0 to STAT_COUNT - 1 do begin
		if (FStat[i].Sent <> 0) or (FStat[i].Rec <> 0) then begin
			Inc(cnt);
      Inc(ssum, FStat[i].Sent);
      Inc(srec, FStat[i].Rec);
    end;
  end;
  if (cnt > 0) then begin
		AStat.Sent := Trunc(ssum / cnt);
    AStat.Rec := Trunc(srec / cnt);
  end else begin
    AStat.Sent := 0;
    AStat.Rec := 0;
  end;
end;

procedure TThrottleProxy.AddStat(const ASent, ARec: Cardinal);
var
	i: integer;
begin
	for i := 1 to STAT_COUNT - 1 do begin
    FStat[i - 1].Sent := FStat[i].Sent;
    FStat[i - 1].Rec := FStat[i].Rec;
  end;
  FStat[STAT_COUNT - 1].Sent := ASent;
  FStat[STAT_COUNT - 1].Rec := ARec;
end;

function TThrottleProxy.GetActive: boolean;
begin
	if Assigned(FServer) then
		Result := FServer.Active
  else
  	Result := false;
end;

procedure TThrottleProxy.SetActive(Value: boolean);
begin
	if FServer = nil then begin
	  FServer := TIdSocksServer.Create(Self);
    FServer.DefaultPort := FPort;
    FServer.OnBeforeSocksConnect := Server_BeforeSocksConnect;
    FServer.OnDisconnect := Server_Disconnect;
    FServer.OnConnect := Server_Connect;
  end;
  if FServer.Active <> Value then begin
    ResetStat;
    if Value then
      AddLog(vNormal, Format('Startup Port %d, %d Bits/s', [FServer.DefaultPort, FBitsPerSec]))
    else
      AddLog(vNormal, 'Shutdown');
    FServer.Active := Value;
  end;
end;

procedure TThrottleProxy.Server_BeforeSocksConnect(AContext: TIdSocksServerContext;
  var VHost: string; var VPort: Word; var VAllowed: Boolean);
var
	Throttle: TIdInterceptThrottler;
  HostStr: string;
begin
	if FResolveHost then
		HostStr := GetHostName(VHost)
  else
  	HostStr := VHost;
	AddLog(vNormal, Format('SOCKS %d: %s:%d', [AContext.SocksVersion, HostStr, VPort]));
  if FBitsPerSec > 0 then begin
    Throttle := TIdInterceptThrottler.Create(AContext.Connection);
    Throttle.BitsPerSec := FBitsPerSec;
    Throttle.OnConnect := Throttle_Connect;
    Throttle.OnDisconnect := Throttle_Disconnect;
    Throttle.OnReceive := Throttle_Receive;
    Throttle.OnSend := Throttle_Send;
    AContext.Connection.Intercept := Throttle;
  end;
end;

procedure TThrottleProxy.Server_Connect(AContext: TIdContext);
begin
	AddLog(vVerbose, 'Connect');
end;

procedure TThrottleProxy.Server_Disconnect(AContext: TIdContext);
begin
	AddLog(vVerbose, 'Disconnect');
end;

procedure TThrottleProxy.Throttle_Connect(ASender: TIdConnectionIntercept);
begin
	AddLog(vVerbose, 'Intercept connect');
end;

procedure TThrottleProxy.Throttle_Disconnect(ASender: TIdConnectionIntercept);
begin
	AddLog(vVerbose, 'Intercept disconnect');
end;

procedure TThrottleProxy.Throttle_Receive(ASender: TIdConnectionIntercept;
  var ABuffer: TArray<System.Byte>);
var
	s: integer;
begin
	s := Length(ABuffer);
  if FRec > Cardinal(MaxInt) then
  	ResetStat;
  Inc(FRec, s);
	AddLog(vVery, Format('Receive: %d B', [s]));
end;

procedure TThrottleProxy.Throttle_Send(ASender: TIdConnectionIntercept;
  var ABuffer: TArray<System.Byte>);
var
	s: integer;
begin
	s := Length(ABuffer);
  if FSent > Cardinal(MaxInt) then
  	ResetStat;
  Inc(FSent, s);
	AddLog(vVery, Format('Send: %d B', [s]));
end;

end.
