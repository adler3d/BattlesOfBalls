unit ASDLog;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 31.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 31.05.07|>}
interface
uses
  Windows, ASDUtils, ASDType,
  ASDInterface;

type
  TLog = class(TASDObject, ILog)
  private
    FTimeStamp: Boolean; // Time Stamp
    FActiveFlush: Boolean; // Active Flush
    FStream: IFileStream;
    FSec: ITimer;
    FLineCount: Integer;
    procedure AddToFile(S: string);
    procedure NextLine(Time: Integer; Sender, Msg: string; ID: string = '');
  public
    constructor CreateEx; override;
    function Create(FileName: PChar): Boolean;
    procedure Print(Sender: IASDObject; Text: PChar);
    function Msg(Caption, Text: PChar; ID: Cardinal): Integer;
    procedure TimeStamp(Active: Boolean);
    procedure Flush(Active: Boolean);
    procedure Free;
    procedure UnLoad; override;
  end;

implementation

uses
  ASDEng;

constructor TLog.CreateEx;
begin
  inherited CreateEx;
  FTimeStamp := True;
  FActiveFlush := False;
end;

function TLog.Create(FileName: PChar): Boolean;
const
  C_H1: string = '<html><head><title>';
  C_H2: string = '</title>'#13#10;
  C_H3: string =
  '<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'#13#10
    + '<style type="text/css">'#13#10'<!--body {background-color: #000000;}' +
    'body,td,th {color: #FFFFFF;font-family: Courier New, Courier, mono;}' +
    'tr#sel {background-color: #666666;} td#c1{width: 70px;text-align: right;}' +
    'td#c2 {text-align: center;width: 100px;}td#rs {background-color: #333333;width: 1px;}'+
    '-->'#13#10'</style></head><body>'#13#10 +
    '<table cellSpacing="1" cellPadding="0" width="100%" border="1" bgcolor="#FF9900"><tr><td>'#13#10
    + '<table id="out" width="100%" border="0" cellpadding="0" cellspacing="1" bgcolor="#000000">'#13#10;
begin
  if FSec = nil then
  begin
    FSec := Tools.InitTimer;
    FSec.Start;
  end;
  Free;
  FStream := Tools.InitFileStream(FileName, fmCreate);
  Result := FStream.Valid;
  FLineCount := 0;
  if Result then
  begin
    AddToFile(C_H1 + ENG_NAME + '[' + FileName + ']' + C_H2 + C_H3);
    NextLine(-1, '', '<b>"' + ENG_NAME + ' ' + ENG_VER + '" log start</b>',
      'sel');
  end;
end;

procedure TLog.Print(Sender: IASDObject; Text: PChar);
var
  S: string;
  Zeit: Integer;
begin
  if FStream.Valid then
  begin
    if FTimeStamp then
    begin
      FSec.Stop;
      Zeit := Round(FSec.Time);
      FSec.Start;
    end;
    if Sender <> nil then
    begin
      S := Sender.ASDName;
      if S[1] = 'T' then
        S := Copy(S, 2, Length(S) - 1);
    end;
    NextLine(Zeit, S, Text);
    if FActiveFlush then
    begin
      //FStream
    end;
  end;
end;

function TLog.Msg(Caption, Text: PChar; ID: Cardinal): Integer;
begin
  Result := MessageBox(Window.Handle, Text, Caption, ID);
end;

procedure TLog.TimeStamp(Active: Boolean);
begin
  FTimeStamp := Active;
end;

procedure TLog.Flush(Active: Boolean);
begin
  FActiveFlush := Active;
end;

procedure TLog.Free;
const
  C_End: string = '</table></table></body></html>'#13#10;
begin
  if FStream = nil then
    Exit;
  AddToFile(C_End);
  FStream.UnLoad;
  FStream := nil;
end;

procedure TLog.UnLoad;
begin
  FSec.UnLoad;
  Print(nil, PChar('ASDAllOBJ = ' + IntToStr(ASDAllOBJ)));
  Print(nil, PChar('ASDCountOBJ = ' + IntToStr(ASDCountOBJ)));
  NextLine(-1, '', '<b>"' + ENG_NAME + ' ' + ENG_VER + '" log close</b>',
    'sel');
  Free;
  inherited UnLoad;
end;

procedure TLog.AddToFile(S: string);
begin
  FStream.Write(S[1], Length(S));
end;

procedure TLog.NextLine(Time: Integer; Sender, Msg: string; ID: string);
const
  C_Space: string = '&nbsp;';
  function F(Teg, ID, Atr, S: string): string;
  begin
    if S = '' then
      S := C_Space;
    if ID <> '' then
      Result := '<' + Teg + ' id="' + ID + '"' + Atr + '>' + S + '</' + Teg + '>'
    else
      Result := '<' + Teg + ' ' + Atr + '>' + S + '</' + Teg + '>';
  end;
var
  RS, V_Time: string;
begin
  Inc(FLineCount);
  if Sender = '' then
    Sender := C_Space;
  if Msg = '' then
    Msg := C_Space;

  V_Time := '';
  if Time <> -1 then
    V_Time := IntToStr(Time);

  RS := '';
  if FLineCount = 1 then
  begin
    RS := F('td', 'rs', 'rowspan="9500"', '');
  end;

  AddToFile(F('tr', ID, '', F('td', 'c1', '', V_Time) + RS +
    F('td', 'c2', '', Sender) + RS + F('td', '', '', Msg)));
end;

end.

