program tpxyc;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  IniFiles,
  uLog in 'uLog.pas',
  uThrottleProxy in 'uThrottleProxy.pas',
  uConsoleLog in 'uConsoleLog.pas';

function KeyPressed: AnsiChar;
var
  lpNumberOfEvents     : DWORD;
  lpBuffer             : TInputRecord;
  lpNumberOfEventsRead : DWORD;
  nStdHandle           : THandle;
begin
  Result := #0;
  //get the console handle
  nStdHandle := GetStdHandle(STD_INPUT_HANDLE);
  lpNumberOfEvents := 0;
  //get the number of events
  GetNumberOfConsoleInputEvents(nStdHandle, lpNumberOfEvents);
  if lpNumberOfEvents <> 0 then
  begin
    //retrieve the event
    PeekConsoleInput(nStdHandle, lpBuffer, 1, lpNumberOfEventsRead);
    if lpNumberOfEventsRead <> 0 then
    begin
      if lpBuffer.EventType = KEY_EVENT then //is a Keyboard event?
      begin
        if lpBuffer.Event.KeyEvent.bKeyDown then //the key was pressed?
          Result := lpBuffer.Event.KeyEvent.AsciiChar
        else
          FlushConsoleInputBuffer(nStdHandle); //flush the buffer
      end
      else
      FlushConsoleInputBuffer(nStdHandle); //flush the buffer
    end;
  end;
end;

var
	gServer: TThrottleProxy;
  c: AnsiChar;
  st: integer;
begin
	WriteLn('Throttle Proxy Copyright (C) 2014');
  WriteLn;
  try
    gServer := TThrottleProxy.Create(nil);
    try
      gServer.Log := TConsoleLog.Create(gServer);
      with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do try
        gServer.BitsPerSec := ReadInteger('proxy', 'bitspersec', 128000);
        gServer.Port := ReadInteger('proxy', 'port', 1080);
        gServer.Log.Verb := TVerbosity(ReadInteger('log', 'verbose', Ord(vNormal)));
        gServer.ResolveHost := ReadBool('log', 'resolvehost', false);
      finally
        Free;
      end;

      WriteLn('Press `q` to quit');
		  WriteLn;
      gServer.Active := true;
      st := 0;

      while gServer.Active do begin
      	c := KeyPressed;
        if (c = 'q') or (c = 'Q') then
        	Break;
        Sleep(100);
        Inc(st, 100);
        if st >= 1000 then begin
        	// Update statistics every 10 sec
          gServer.UpdateStat;
          st := 0;
        end;
      end;

      with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do try
        WriteInteger('proxy', 'bitspersec', gServer.BitsPerSec);
        WriteInteger('proxy', 'port', gServer.Port);
        WriteInteger('log', 'verbose', Ord(gServer.Log.Verb));
        WriteBool('log', 'resolvehost', gServer.ResolveHost);
      finally
        Free;
      end;

      if gServer.Active then
      	gServer.Active := false;
    finally
      gServer.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
