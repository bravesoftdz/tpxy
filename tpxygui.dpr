program tpxygui;

uses
  Vcl.Forms,
  frmMain in 'frmMain.pas' {MainForm},
  uThrottleProxy in 'uThrottleProxy.pas',
  uLog in 'uLog.pas',
  uMemoLog in 'uMemoLog.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
