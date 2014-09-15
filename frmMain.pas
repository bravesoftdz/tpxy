unit frmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.Menus, Vcl.StdCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer,
  Vcl.ExtCtrls, Vcl.ComCtrls, uThrottleProxy, uMemoLog;

type
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
    actVerbNone: TAction;
    None1: TMenuItem;
    N2: TMenuItem;
    procedure actFileExitExecute(Sender: TObject);
    procedure actProxyActiveUpdate(Sender: TObject);
    procedure actProxyActiveExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure actProxySpeedExecute(Sender: TObject);
    procedure actEditClearExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actProxyPortExecute(Sender: TObject);
    procedure actVerbNormalUpdate(Sender: TObject);
    procedure actVerbNormalExecute(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
    procedure actLogResolveHostUpdate(Sender: TObject);
    procedure actLogResolveHostExecute(Sender: TObject);
  private
    { Private-Deklarationen }
    FServer: TThrottleProxy;
    procedure SetActive(const AActive: boolean);
    procedure ReadSettings;
    procedure WriteSettings;
    procedure UpdateStatusbar;
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

uses
	IniFiles, uLog;

{$R *.dfm}

resourcestring
	SAppTitle = 'Throttle Proxy';

procedure TMainForm.SetActive(const AActive: boolean);
const
	ACT: array[boolean] of string = ('Inactive', 'Active');
begin
  if FServer.Active <> AActive then begin
  	FServer.Active := AActive;
    tmrStatus.Enabled := AActive;
  	Caption := Format('%s [%s]', [SAppTitle, ACT[FServer.Active]]);
  end;
end;

procedure TMainForm.tmrStatusTimer(Sender: TObject);
begin
	UpdateStatusbar;
end;

procedure TMainForm.ReadSettings;
begin
  with TInifile.Create(ChangeFileExt(Application.ExeName, '.ini')) do try
    FServer.BitsPerSec := ReadInteger('proxy', 'bitspersec', 128000);
    FServer.Port := ReadInteger('proxy', 'port', 1080);
    FServer.Log.Verb := TVerbosity(ReadInteger('log', 'verbose', Ord(vNormal)));
    FServer.ResolveHost := ReadBool('log', 'resolvehost', false);
  finally
    Free;
  end;
end;

procedure TMainForm.WriteSettings;
begin
  with TInifile.Create(ChangeFileExt(Application.ExeName, '.ini')) do try
    WriteInteger('proxy', 'bitspersec', FServer.BitsPerSec);
    WriteInteger('proxy', 'port', FServer.Port);
    WriteInteger('log', 'verbose', Ord(FServer.Log.Verb));
    WriteBool('log', 'resolvehost', FServer.ResolveHost);
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
	FServer.ResolveHost := not FServer.ResolveHost;
end;

procedure TMainForm.actLogResolveHostUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := FServer.ResolveHost;
end;

procedure TMainForm.actProxyActiveExecute(Sender: TObject);
begin
	SetActive(not FServer.Active);
end;

procedure TMainForm.actProxyActiveUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := FServer.Active;
end;

procedure TMainForm.actProxyPortExecute(Sender: TObject);
var
	val: string;
  act: boolean;
begin
	val := IntToStr(FServer.Port);
	if InputQuery('Port', 'Enter Port', val) then begin
  	act := FServer.Active;
    if act then
			SetActive(false);
		FServer.Port := StrToInt(val);
    if act then
			SetActive(true);
  end;
end;

procedure TMainForm.actProxySpeedExecute(Sender: TObject);
var
	val: string;
  act: boolean;
begin
	val := IntToStr(FServer.BitsPerSec);
	if InputQuery('Max sspeed', 'Max speed in Bits/s. per connection.'#13#10'0 = unlimited.', val) then begin
  	act := FServer.Active;
    if act then
			SetActive(false);
		FServer.BitsPerSec := StrToInt(val);
    if act then
			SetActive(true);
  end;
end;

procedure TMainForm.UpdateStatusbar;
var
	st: TStatItem;
begin
	FServer.UpdateStat;
  FServer.AvgStat(st);

  sbMain.SimpleText := Format('Sent: %d Bits/s; Rec: %d Bits/s; Total: %d Bits/s', [st.Sent, st.Rec, st.Sent + st.Rec]);
end;

procedure TMainForm.actVerbNormalExecute(Sender: TObject);
begin
	FServer.Log.Verb := TVerbosity((Sender as TAction).Tag);
end;

procedure TMainForm.actVerbNormalUpdate(Sender: TObject);
begin
	(Sender as TAction).Checked := Ord(FServer.Log.Verb) = (Sender as TAction).Tag;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	SetActive(false);
  WriteSettings;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
	Caption := SAppTitle;
  FServer := TThrottleProxy.Create(Self);
	FServer.BitsPerSec := 128000;
  FServer.Log := TMemoLog.Create(FServer);
  TMemoLog(FServer.Log).Memo := mLog;
  FServer.Log.Verb := vNormal;
  FServer.ResolveHost := false;
  ReadSettings;
	SetActive(true);
end;

end.
