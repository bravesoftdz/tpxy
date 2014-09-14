unit frmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, System.Actions, Vcl.ActnList,
  Vcl.Menus, Vcl.StdCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdTCPServer, IdCmdTCPServer, IdHTTPProxyServer, IdSocksServer, IdIOHandler,
  IdIOHandlerStream, IdIntercept, IdInterceptThrottler, Vcl.ExtCtrls;

type
	TVerbosity = (vNormal, vVerbose, vVery);

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
  private
    { Private-Deklarationen }
    FBitsPerSec: Integer;
    FVerbosity: TVerbosity;
    procedure SetActive(const AActive: boolean);
    procedure AddLog(const AMsg: string);
    procedure ReadSettings;
    procedure WriteSettings;
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

uses
	IdTCPConnection, IdTCPStream, IdGlobal, IniFiles;

{$R *.dfm}

resourcestring
	SAppTitle = 'Throttle Proxy';

procedure TMainForm.SetActive(const AActive: boolean);
const
	ACT: array[boolean] of string = ('Inactive', 'Active');
begin
  if ipsMain.Active <> AActive then begin
  	ipsMain.Active := AActive;
  	Caption := Format('%s [%s]', [SAppTitle, ACT[ipsMain.Active]]);
    if AActive then
    	AddLog(Format('Startup Port %d, %d Bit/s', [ipsMain.DefaultPort, FBitsPerSec]))
    else
    	Addlog('Shutdown');
  end;
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
	if InputQuery('Max Speed', 'Max Speed in Bits per sec. 0 = unlimited.', val) then begin
  	act := ipsMain.Active;
    if act then
			SetActive(false);
		FBitsPerSec := StrToInt(val);
    if act then
			SetActive(true);
  end;
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
begin
	if FVerbosity >= vVery then
		AddLog(Format('Receive: %d B', [Length(ABuffer)]));
end;

procedure TMainForm.idThrottleSend(ASender: TIdConnectionIntercept;
  var ABuffer: TArray<System.Byte>);
begin
	if FVerbosity >= vVery then
		AddLog(Format('Send: %d B', [Length(ABuffer)]));
end;

procedure TMainForm.ipsMainBeforeSocksConnect(AContext: TIdSocksServerContext;
  var VHost: string; var VPort: Word; var VAllowed: Boolean);
var
	Throttle: TIdInterceptThrottler;
begin
	AddLog(Format('SOCKS%d: %s:%d', [AContext.SocksVersion, VHost, VPort]));
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
