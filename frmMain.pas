unit frmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, System.Actions, Vcl.ActnList,
  Vcl.Menus, Vcl.StdCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdTCPServer, IdCmdTCPServer, IdHTTPProxyServer, IdSocksServer, IdIOHandler,
  IdIOHandlerStream, IdIntercept, IdInterceptThrottler, Vcl.ExtCtrls,
  Vcl.ComCtrls;

const
	STAT_COUNT = 10;

type
	TVerbosity = (vNormal, vVerbose, vVery);
  TStatItem = record
    Sent: Cardinal;
    Rec: Cardinal;
  end;
  TStat = array[0..STAT_COUNT - 1] of TStatItem;

  TMainForm = class(TForm)
    mLog: TMemo;
    mnuMain: TMainMenu;
    File1: TMenuItem;
    Proxy1: TMenuItem;
    actlMain: TActionList;
    actFileExit: TAction;
    Exit1: TMenuItem;
    actProxyActive: TAction;
    Active1: TMenuItem;
    ipsMain: TIdSocksServer;
    actProxySpeed: TAction;
    MaxSpeed1: TMenuItem;
    Edit1: TMenuItem;
    actEditClear: TAction;
    Clear1: TMenuItem;
    tiMain: TTrayIcon;
    actProxyPort: TAction;
    Port1: TMenuItem;
    N1: TMenuItem;
    actVerbNormal: TAction;
    actVerbVerbose: TAction;
    actVerbVery: TAction;
    Verbosity1: TMenuItem;
    Normal1: TMenuItem;
    Verbose1: TMenuItem;
    Veryverbose1: TMenuItem;
    sbMain: TStatusBar;
    tmrStatus: TTimer;
    actLogResolveHost: TAction;
    ResolveHost1: TMenuItem;
    procedure actFileExitExecute(Sender: TObject);
    procedure actProxyActiveUpdate(Sender: TObject);
    procedure actProxyActiveExecute(Sender: TObject);
    procedure ipsMainBeforeSocksConnect(AContext: TIdSocksServerContext;
      var VHost: string; var VPort: Word; var VAllowed: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure idThrottleConnect(ASender: TIdConnectionIntercept);
    procedure idThrottleDisconnect(ASender: TIdConnectionIntercept);
    procedure idThrottleReceive(ASender: TIdConnectionIntercept;
      var ABuffer: TArray<System.Byte>);
    procedure idThrottleSend(ASender: TIdConnectionIntercept;
      var ABuffer: TArray<System.Byte>);
    procedure actProxySpeedExecute(Sender: TObject);
    procedure ipsMainConnect(AContext: TIdContext);
    procedure actEditClearExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ipsMainDisconnect(AContext: TIdContext);
    procedure actProxyPortExecute(Sender: TObject);
    procedure actVerbNormalUpdate(Sender: TObject);
    procedure actVerbNormalExecute(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
    procedure actLogResolveHostUpdate(Sender: TObject);
    procedure actLogResolveHostExecute(Sender: TObject);
  private
    { Private-Deklarationen }
    FBitsPerSec: Integer;
    FVerbosity: TVerbosity;
    FRec, FSent: Cardinal;
    FStartTime: TDateTime;
    FStat: TStat;
    FResolveHost: boolean;
    function GetHostName(const AIP: string): string;
    procedure SetActive(const AActive: boolean);
    procedure AddLog(const AMsg: string);
    procedure ReadSettings;
    procedure WriteSettings;
    procedure UpdateStatusbar;
    procedure ResetStat;
    procedure AddStat(const ASent, ARec: Cardinal);
    procedure AvgStat(var AStat: TStatItem);
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

uses
	IdTCPConnection, IdTCPStream, IdGlobal, IniFiles, DateUtils, Winapi.Winsock2;

{$R *.dfm}

resourcestring
	SAppTitle = 'Throttle Proxy';

procedure TMainForm.ResetStat;
begin
  FRec := 0;
  FSent := 0;
  FStartTime := Now;
end;

procedure TMainForm.SetActive(const AActive: boolean);
const
	ACT: array[boolean] of string = ('Inactive', 'Active');
begin
  if ipsMain.Active <> AActive then begin
  	ResetStat;
  	ipsMain.Active := AActive;
    tmrStatus.Enabled := AActive;
  	Caption := Format('%s [%s]', [SAppTitle, ACT[ipsMain.Active]]);
    if AActive then
    	AddLog(Format('Startup Port %d, %d Bit/s', [ipsMain.DefaultPort, FBitsPerSec]))
    else
    	Addlog('Shutdown');
  end;
end;

procedure TMainForm.AddStat(const ASent, ARec: Cardinal);
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

procedure TMainForm.AvgStat(var AStat: TStatItem);
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

procedure TMainForm.tmrStatusTimer(Sender: TObject);
begin
	UpdateStatusbar;
end;

procedure TMainForm.AddLog(const AMsg: string);
begin
	mLog.Lines.Add(Format('%s: %s', [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;

procedure TMainForm.ReadSettings;
begin
  with TInifile.Create(ChangeFileExt(Application.ExeName, '.ini')) do try
    FBitsPerSec := ReadInteger('proxy', 'bitspersec', 128000);
    ipsMain.DefaultPort := ReadInteger('proxy', 'port', 1080);
    FVerbosity := TVerbosity(ReadInteger('log', 'verbose', Ord(vNormal)));
    FResolveHost := ReadBool('log', 'resolvehost', false);
  finally
    Free;
  end;
end;

procedure TMainForm.WriteSettings;
begin
  with TInifile.Create(ChangeFileExt(Application.ExeName, '.ini')) do try
    WriteInteger('proxy', 'bitspersec', FBitsPerSec);
    WriteInteger('proxy', 'port', ipsMain.DefaultPort);
    WriteInteger('log', 'verbose', Ord(FVerbosity));
    WriteBool('log', 'resolvehost', FResolveHost);
  finally
    Free;
  end;
end;

procedure TMainForm.actEditClearExecute(Sender: TObject);
begin
	mLog.Lines.Clear;
end;

procedure TMainForm.actFileExitExecute(Sender: TObject);
begin
	Close;
end;

procedure TMainForm.actLogResolveHostExecute(Sender: TObject);
begin
	FResolveHost := not FResolveHost;
end;

procedure TMainForm.actLogResolveHostUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := FResolveHost;
end;

procedure TMainForm.actProxyActiveExecute(Sender: TObject);
begin
	SetActive(not ipsMain.Active);
end;

procedure TMainForm.actProxyActiveUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := ipsMain.Active;
end;

procedure TMainForm.actProxyPortExecute(Sender: TObject);
var
	val: string;
  act: boolean;
begin
	val := IntToStr(ipsMain.DefaultPort);
	if InputQuery('Port', 'Enter Port', val) then begin
  	act := ipsMain.Active;
    if act then
			SetActive(false);
		ipsMain.DefaultPort := StrToInt(val);
    if act then
			SetActive(true);
  end;
end;

procedure TMainForm.actProxySpeedExecute(Sender: TObject);
var
	val: string;
  act: boolean;
begin
	val := IntToStr(FBitsPerSec);
	if InputQuery('Max sspeed', 'Max speed in Bits/s. per connection.'#13#10'0 = unlimited.', val) then begin
  	act := ipsMain.Active;
    if act then
			SetActive(false);
		FBitsPerSec := StrToInt(val);
    if act then
			SetActive(true);
  end;
end;

procedure TMainForm.UpdateStatusbar;
var
	td: integer;
  sps, spr: integer;
  st: TStatItem;
begin
  td := SecondsBetween(Now, FStartTime);
  if td > 0 then begin
    sps := Trunc(FSent / td) * 8;
    spr := Trunc(FRec / td) * 8;
  end else begin
    sps := 0;
    spr := 0;
  end;
  AddStat(sps, spr);
  AvgStat(st);
  if (td > 10) then
  	ResetStat;

  sbMain.SimpleText := Format('Sent: %d Bits/s; Rec: %d Bits/s; Total: %d Bits/s', [st.Sent, st.Rec, st.Sent + st.Rec]);
end;

procedure TMainForm.actVerbNormalExecute(Sender: TObject);
begin
	FVerbosity := TVerbosity((Sender as TAction).Tag);
end;

procedure TMainForm.actVerbNormalUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := Ord(FVerbosity) = (Sender as TAction).Tag;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	SetActive(false);
  WriteSettings;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
	Caption := SAppTitle;
	FBitsPerSec := 128000;
  FVerbosity := vNormal;
  FResolveHost := false;
  ReadSettings;
	SetActive(true);
end;

procedure TMainForm.idThrottleConnect(
  ASender: TIdConnectionIntercept);
begin
	if FVerbosity >= vVerbose then
		AddLog('Intercept Connect');
end;

procedure TMainForm.idThrottleDisconnect(
  ASender: TIdConnectionIntercept);
begin
	if FVerbosity >= vVerbose then
		AddLog('Intercept Disconnect');
end;

procedure TMainForm.idThrottleReceive(
  ASender: TIdConnectionIntercept; var ABuffer: TArray<System.Byte>);
var
	s: integer;
begin
	s := Length(ABuffer);
  if FRec > Cardinal(MaxInt) then
  	ResetStat;
  Inc(FRec, s);
	if FVerbosity >= vVery then
		AddLog(Format('Receive: %d B', [s]));
end;

procedure TMainForm.idThrottleSend(ASender: TIdConnectionIntercept;
  var ABuffer: TArray<System.Byte>);
var
	s: integer;
begin
	s := Length(ABuffer);
  if FSent > Cardinal(MaxInt) then
  	ResetStat;
  Inc(FSent, s);
	if FVerbosity >= vVery then
		AddLog(Format('Send: %d B', [s]));
end;

function TMainForm.GetHostName(const AIP: string): string;
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
end;

procedure TMainForm.ipsMainBeforeSocksConnect(AContext: TIdSocksServerContext;
  var VHost: string; var VPort: Word; var VAllowed: Boolean);
var
	Throttle: TIdInterceptThrottler;
  HostStr: string;
begin
	if FResolveHost then
		HostStr := GetHostName(VHost)
  else
  	HostStr := VHost;
	AddLog(Format('SOCKS%d: %s:%d', [AContext.SocksVersion, HostStr, VPort]));
  Throttle := TIdInterceptThrottler.Create(AContext.Connection);
  Throttle.BitsPerSec := FBitsPerSec;
  Throttle.OnConnect := idThrottleConnect;
  Throttle.OnDisconnect := idThrottleDisconnect;
  Throttle.OnReceive := idThrottleReceive;
  Throttle.OnSend := idThrottleSend;
  AContext.Connection.Intercept := Throttle;
end;

procedure TMainForm.ipsMainConnect(AContext: TIdContext);
begin
	if FVerbosity >= vVerbose then
		AddLog('Connect');
end;

procedure TMainForm.ipsMainDisconnect(AContext: TIdContext);
begin
	if FVerbosity >= vVerbose then
		AddLog('Disconnect');
end;

end.
