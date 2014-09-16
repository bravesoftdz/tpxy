unit svcMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, uThrottleProxy;

type
  TThrottleProxyService = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
  private
    { Private-Deklarationen }
    FServer: TThrottleProxy;
  public
    function GetServiceController: TServiceController; override;
    { Public-Deklarationen }
  end;

var
  ThrottleProxyService: TThrottleProxyService;

implementation

uses
	IniFiles;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ThrottleProxyService.Controller(CtrlCode);
end;

function TThrottleProxyService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TThrottleProxyService.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
	FServer.Active := true;
end;

procedure TThrottleProxyService.ServiceCreate(Sender: TObject);
begin
  FServer := TThrottleProxy.Create(Self);
  with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do try
    FServer.BitsPerSec := ReadInteger('proxy', 'bitspersec', 128000);
    FServer.Port := ReadInteger('proxy', 'port', 1080);
    FServer.ResolveHost := ReadBool('log', 'resolvehost', false);
  finally
    Free;
  end;
end;

procedure TThrottleProxyService.ServiceDestroy(Sender: TObject);
begin
	if FServer.Active then
		FServer.Active := false;
end;

procedure TThrottleProxyService.ServicePause(Sender: TService; var Paused: Boolean);
begin
	FServer.Active := false;
end;

procedure TThrottleProxyService.ServiceStart(Sender: TService; var Started: Boolean);
begin
	FServer.Active := true;
end;

procedure TThrottleProxyService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
	FServer.Active := false;
end;

end.
