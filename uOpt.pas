unit uOpt;

interface

uses
	System.SysUtils, System.Classes;

function GetOpt(const AC: Char; const ADefault: string): string; overload;
function GetOpt(const AC: Char; const ADefault: integer): integer; overload;
function GetOpt(const AC: Char; const ADefault: boolean): boolean; overload;

implementation

function GetOpt(const AC: Char; const ADefault: string): string;
var
	i: integer;
  s: string;
begin
	for i := 1 to ParamCount do begin
		s := ParamStr(i);
    if Length(s) > 2 then begin
      if (s[1] = '-') or (s[1] = '/') then begin
        if s[2] = AC then begin
          Result := Copy(s, 3, MaxInt);
          if Result = '' then
          	Result := 'True';
          Exit;
        end;
      end;
    end;
  end;
  Result := ADefault;
end;

function GetOpt(const AC: Char; const ADefault: integer): integer;
var
	s: string;
begin
	s := GetOpt(AC, IntToStr(ADefault));
  if s = '' then
  	Result := 0
  else
  	Result := StrToInt(s);
end;

function GetOpt(const AC: Char; const ADefault: boolean): boolean;
var
	s: string;
  d: string;
begin
	if ADefault then
  	d := 'True'
  else
  	d := 'False';
	s := GetOpt(AC, d);
  if s = '' then
  	Result := false
  else
  	Result := SameText(s, 'true');
end;

end.
