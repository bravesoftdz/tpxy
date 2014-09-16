program tpxyc;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  IniFiles,
  uLog in 'uLog.pas',
  uThrottleProxy in 'uThrottleProxy.pas',
  uConsoleLog in 'uConsoleLog.pas',
  uOpt in 'uOpt.pas';

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

procedure ShowHelp;
begin
  WriteLn('Usage');
  WriteLn(' ' + ExtractFileName(ParamStr(0)) + ' [-<options>]');
  WriteLn('options:');
  WriteLn(' B<integer>     Limit to Bits per sec.');
  WriteLn(' P<integer>     Bind to port');
  WriteLn(' H<true|false>  Resolve host name');
  WriteLn(' V<0..3>        Verbosity, 0 = none, 3 = very');
  WriteLn(' s<true|false>  Save settings, default True');
end;

var
	gServer: TThrottleProxy;
  c: AnsiChar;
  st: integer;
  save_sett: boolean;
begin
	WriteLn('Throttle Proxy Copyright (C) 2014');
  WriteLn;
  if FindCmdLineSwitch('h', ['-', '/'], false) then begin
  	ShowHelp;
  	Halt(0);
  end;

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

      save_sett := true;
      if ParamCount > 0 then begin
        gServer.BitsPerSec := GetOpt('B', gServer.BitsPerSec);
        gServer.Port := GetOpt('P', gServer.Port);
        gServer.ResolveHost := GetOpt('H', gServer.ResolveHost);
        gServer.Log.Verb := TVerbosity(GetOpt('V', Ord(gServer.Log.Verb)));
        save_sett := GetOpt('s', save_sett);
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

      if save_sett then begin
        with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do try
          WriteInteger('proxy', 'bitspersec', gServer.BitsPerSec);
          WriteInteger('proxy', 'port', gServer.Port);
          WriteInteger('log', 'verbose', Ord(gServer.Log.Verb));
          WriteBool('log', 'resolvehost', gServer.ResolveHost);
        finally
          Free;
        end;
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
