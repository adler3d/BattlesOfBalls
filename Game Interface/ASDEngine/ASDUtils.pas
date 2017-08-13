unit ASDUtils;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 5.07.07|>}
interface
//{$D-}
uses
  Windows {, TypVectors}, ASDType;

function GetProgTime: Real;
function GetTime: Real;
function IntToStr(Value: Integer): string;
function FloatToStr(Value: Single; W, H: Integer): string;
function StrToInt(const S: string): Integer;

function StrToIntDef(const S: string; Default: Integer): Integer;
function LowerCase(const s: string): string;

function ExtractFileExt(const FileName: string): string;
function ExtractFileName(const FileName: string): string;
function ExtractFilePath(const FileName: string): string;
function ChangeFileExt(const FileName, Extension: string): string;

function FileOpen(const FileName: string; Mode: Integer): HFile;
function FileCreate(const FileName: string): HFile;
function FileValid(F: HFile): Boolean;
procedure FileClose(var F: HFile);
procedure FileFlush(F: HFile);
function FileWrite(F: HFile; const Buf; Count: DWORD): DWORD;
function FileRead(F: HFile; var Buf; Count: DWORD): DWORD;
function FileSeek(F: HFile; Offset: Integer;
  Origin: Integer = FILE_BEGIN): Integer;
function FileSize(F: HFile): DWORD;
function FilePos(F: HFile): DWORD;
function SysErrorMessage(ErrorCode: Integer): string;

const
  BoolArr: array [Boolean] of string = ('False','True');

implementation

var
  Freq: Int64; //Частота системнога таймера
  LastTime: Int64; //Последнеее время вызова
  StartTime: Real; //Время запуска программы

function FloatToStr(Value: Single; W, H: Integer): string;
begin
  Str(Value: W: H, Result);
  {Result:=IntToStr(Trunc(Value))+'.';
  Result:=Result+IntToStr(Round(1000*Frac(Value)));}
end;

function SysErrorMessage(ErrorCode: Integer): string;
var
  Buffer: array[0..255] of Char;
var
  Len: Integer;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_IGNORE_INSERTS or
    FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, ErrorCode, 0, Buffer,
    SizeOf(Buffer), nil);
  while (Len > 0) and (Buffer[Len - 1] in [#0..#32, '.']) do
    Dec(Len);
  SetString(Result, Buffer, Len);
end;

function GetProgTime: Real;
begin
  QueryPerformanceCounter(LastTime);
  Result := (LastTime / Freq) - StartTime;
end;

function LowerCase(const s: string): string;
var
  i, l: integer;
  Rc, Sc: PChar;
begin
  l := Length(s);
  SetLength(Result, l);
  Rc := Pointer(Result);
  Sc := Pointer(s);
  for i := 1 to l do
  begin
    if s[i] in ['A'..'Z', 'А'..'Я'] then
      Rc^ := Char(Byte(Sc^) + 32)
    else
      Rc^ := Sc^;
    inc(Rc);
    inc(Sc);
  end;
end;

function ExtractFileExt(const FileName: string): string;
var
  i: Integer;
begin
  for i := Length(FileName) downto 1 do
    if FileName[i] = '.' then
    begin
      Result := Copy(FileName, i + 1, Length(FileName));
      Exit;
    end;
  Result := '';
end;

function FileCreate(const FileName: string): HFile;
begin
  Result := Integer(CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
    0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0));
end;

function FileOpen(const FileName: string; Mode: Integer): HFile;
const
  AccessMode: array[0..2] of LongWord = (
    GENERIC_READ,
    GENERIC_WRITE,
    GENERIC_READ or GENERIC_WRITE);
  ShareMode: array[0..4] of LongWord = (
    0,
    0,
    FILE_SHARE_READ,
    FILE_SHARE_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE);
begin
  Result := NULL_FILE;
  if ((Mode and 3) <= fmOpenReadWrite) and
    ((Mode and $F0) <= fmShareDenyNone) then
    Result := Integer(CreateFile(PChar(FileName), AccessMode[Mode and 3],
      ShareMode[(Mode and $F0) shr 4], nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0));
end;

function FileValid(F: HFile): Boolean;
begin
  Result := F <> NULL_FILE;
end;

procedure FileClose(var F: HFile);
begin
  if F <> NULL_FILE then
  begin
    CloseHandle(F);
    F := NULL_FILE;
  end;
end;

procedure FileFlush(F: HFile);
begin
  FlushFileBuffers(F);
end;

function FileWrite(F: HFile; const Buf; Count: DWORD): DWORD;
begin
  WriteFile(F, Buf, Count, Result, nil);
end;

function FileRead(F: HFile; var Buf; Count: DWORD): DWORD;
begin
  ReadFile(F, Buf, Count, Result, nil);
end;

function FileSeek(F: HFile; Offset: Integer;
  Origin: Integer = FILE_BEGIN): Integer;
begin
  Result := SetFilePointer(F, Offset, nil, Origin);
end;

function FileSize(F: HFile): DWORD;
begin
  Result := GetFileSize(F, nil);
end;

function FilePos(F: HFile): DWORD;
begin
  Result := SetFilePointer(F, 0, nil, FILE_CURRENT);
end;

function IntToStr(Value: Integer): string;
begin
  Str(Value, Result);
end;

function StrToInt(const S: string): Integer;
var
  er: Integer;
begin
  Val(S, Result, er);
end;

function StrToIntDef(const S: string; Default: Integer): Integer;
var
  er: Integer;
begin
  Val(S, Result, er);
  if er = 0 then
    Result := Default;
end;

function GetTime: Real;
begin
  QueryPerformanceCounter(LastTime);
  Result := LastTime / Freq;
end;

procedure InitASDUtils;
begin
  QueryPerformanceFrequency(Freq);
  StartTime := GetTime;
end;

function ExtractFilePath(const FileName: string): string;
//||C:\Windows\System32\mspaint.exe||||||||||||||||||||||//
//||<---------I-------->           ||||||||||||||||||||||//
var
  I: Integer;
begin
  for I := Length(FileName) downto 1 do
  begin
    if (FileName[I] = '\') then
    begin
      Break;
    end;
  end;
  Result := Copy(FileName, 1, I);
  Exit;
end;

function ExtractFileName(const FileName: string): string;
//||C:\Windows\System32\mspaint.exe||||||||||||||||||||||//
//||<---------I-------->           ||||||||||||||||||||||//
var
  I: Integer;
begin
  for I := Length(FileName) downto 1 do
  begin
    if (FileName[I] = '\') then
    begin
      Break;
    end;
  end;
  Result := Copy(FileName, I+1, Length(FileName)-I);
  Exit;
end;

function ChangeFileExt(const FileName, Extension: string): string;
//||C:\Windows\System32\mspaint.exe||||||||||||||||||||||
//||<---------I-------->       <-E>||||||||||||||||||||||
var
  I, E: Integer;
label
  G;
begin
  for I := Length(FileName) downto 1 do
  begin
    if (FileName[I] = '.') then
    begin
      goto G;
    end;
  end;
  Result := FileName;
  Exit;
  G:
  E := Length(FileName) - I;
  for I := E - 1 downto 1 do
    if (FileName[I] = '\') then
    begin
      Break;
    end;
  Result := Copy(FileName, I + 1, Length(FileName) - E - 1)+Extension;
  Exit;
end;

//=== Exception ===-----------------------------
function GetExceptionObject(P: PExceptionRecord): TObject;
begin
  Result := TObject.Create;
end;

procedure ErrorHandler(ErrorCode: Byte; ErrorAddr: Pointer); export;
begin
  raise TObject.Create at ErrorAddr;
end;

procedure ExceptHandler(ExceptObject: TObject; ExceptAddr: Pointer); far;
begin
  //
end;

initialization
  ErrorProc      := ErrorHandler;
  ExceptProc     := @ExceptHandler;
  ExceptionClass := TObject;
  ExceptObjProc  := @GetExceptionObject;
  InitASDUtils;
end.

