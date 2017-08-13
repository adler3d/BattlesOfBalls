unit ASDTools;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 5.07.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 5.07.07|>}
interface

uses ASDInterface, ASDClasses;

type
  TTools = class(TASDObject, ITools)
  public
    constructor CreateEx; override;
    function InitCalcNPS(WaitTime: Integer = 500): ICalcNPS;
    function InitTimer: ITimer;
    function InitFileStream(FileName: PChar; Mode: Word = 0): IFileStream;
    function InitList: IList;
    function InitQuickList: IList;
    function InitMemoryStream: IMemoryStream;
    function InitMemoryStreamEx(Memory: Pointer; Size: Integer): IMemoryStream;
  end;

implementation

uses ASDEng;

{ TASDTools }

constructor TTools.CreateEx;
begin
  inherited CreateEx;
end;

function TTools.InitCalcNPS(WaitTime: Integer): ICalcNPS;
begin
  Result := TCalcNPS.CreateEx(WaitTime);
end;

function TTools.InitFileStream(FileName: PChar;
  Mode: Word): IFileStream;
begin
  Result := TFileStream.CreateEx(FileName, Mode);
end;

function TTools.InitList: IList;
begin
  Result := TList.CreateEx;
end;

function TTools.InitQuickList: IList;
begin
  Result := TQuickList.CreateEx;
end;

function TTools.InitMemoryStream: IMemoryStream;
begin
  Result := TMemoryStream.CreateEx;
end;

function TTools.InitMemoryStreamEx(Memory: Pointer; Size: Integer):
  IMemoryStream;
begin
  Result := TMemoryStream.CreateEx(Memory, Size);
end;

function TTools.InitTimer: ITimer;
begin
  Result := TTimer.CreateEx;
end;

end.

 