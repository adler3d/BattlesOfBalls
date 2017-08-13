unit ASDTGA;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 29.05.07|>}
interface

uses
  {ASDUtils,} ASDType, ASDClasses;

function LoadTGA(const FileName: PChar; var Width, Height, BPP: Integer; var Data: PByteArray): Boolean;
function LoadTGAmem(Mem: Pointer; Size: Integer; var Width, Height, BPP: Integer; var Data: PByteArray): Boolean;

implementation

const
  TARGA_NO_COLORMAP = 0;
  TARGA_COLORMAP = 1;
  TARGA_EMPTY_IMAGE = 0;
  TARGA_INDEXED_IMAGE = 1;
  TARGA_TRUECOLOR_IMAGE = 2;
  TARGA_BW_IMAGE = 3;

type
  PWordArray = ^TWordArray;
  TWordArray = array[0..1] of Word;

// Описание заголовка TARGA формата
  TGA_Header = packed record
    FileType: Byte;
    ColorMapType: Byte;
    ImageType: Byte;
    ColorMapStart: Word;
    ColorMapLength: Word;
    ColorMapDepth: Byte;
    OrigX: Word;
    OrigY: Word;
    Width: Word;
    Height: Word;
    BPP: Byte;
    ImageInfo: Byte;
  end;

//== Основная функция модуля - загрузка TARGA изображения

function LoadImage(Stream: TStream; var Width, Height, BPP: Integer; var Data: PByteArray): Boolean;
var
  i: Integer;
  TGA: TGA_Header; // текущий заголовок
  i_buf: PByteArray; // буфер изображение
  ColorMap: PByteArray;

  procedure Flip_H;
  var
    i, j, x: Integer;
    b, t: Byte;
  begin
  //== Отобразить по горизонтали
    b := BPP div 8;
    for i := 0 to Height - 1 do
    begin
      for x := 0 to Width div 2 - 1 do
        for j := 0 to b - 1 do
        begin
          t := Data[(i * Width + x) * b + j];
          Data[(i * Width + x) * b + j] := Data[(i * Width + width - x - 1) * b + j];
          Data[(i * Width + width - x - 1) * b + j] := t;
        end;
    end;
  end;

  procedure Flip_V;
  var
    p: PByteArray;
    i: Integer;
    b: Byte;
  begin
  //== Отобразить по вертикали
    b := BPP div 8;
    GetMem(p, Width * b);
    for i := 0 to Height div 2 - 1 do
    begin
      Move(Data[i * Width * b], p^, Width * b);
      Move(Data[(Height - i - 1) * Width * b], Data[i * Width * b], Width * b);
      Move(p^, Data[(Height - i - 1) * Width * b], Width * b);
    end;
    FreeMem(p);
  end;

begin
  Result := False;
  if not Stream.Valid then
    Exit;

  with TGA do
  begin
  // Читаем заголовок
    Stream.Read(TGA, SizeOf(TGA));
    Stream.Seek(SizeOf(TGA) + TGA.FileType);
  // Нужны не сжатые, 8 + ч/б, 16, 24, 32 битные
    if not ((ImageType = TARGA_INDEXED_IMAGE) or
      (ImageType = TARGA_TRUECOLOR_IMAGE) or
      (ImageType = TARGA_BW_IMAGE)) then
      Exit;

  // Выделяем память под палитру - если нужна
    ColorMap := nil;
    if ImageType = TARGA_INDEXED_IMAGE then
      if (ColorMapType = TARGA_COLORMAP) and
        (ColorMapDepth = 24) then
      begin
        GetMem(ColorMap, ColorMapLength * 3);
        Stream.Read(ColorMap^, ColorMapLength * 3);
      end else
        Exit;
  end;

  GetMem(i_buf, Stream.Size - Stream.Position);
  Stream.Read(i_buf^, Stream.Size - Stream.Position);

  Width := TGA.Width;
  Height := TGA.Height;
  if TGA.BPP < 32 then
    BPP := 24
  else
    BPP := 32;

// Выделяем память под озображение
  if TGA.BPP < 24 then
    GetMem(Data, Width * Height * BPP div 8);

// Готовим буфер под изображение
  with TGA do
  begin
  // Читаем изображение в зависимости от его типа и битности
    case BPP of // TGA.BPP
      8: if ImageType = TARGA_INDEXED_IMAGE then
        begin
          for i := 0 to Width * Height - 1 do
          begin
            Data[i * 3] := ColorMap[i_buf[i] * 3];
            Data[i * 3 + 1] := ColorMap[i_buf[i] * 3 + 1];
            Data[i * 3 + 2] := ColorMap[i_buf[i] * 3 + 2];
          end;
          FreeMem(ColorMap);
        end else
          for i := 0 to Width * Height - 1 do
          begin
            Data[i * 3] := i_buf[i];
            Data[i * 3 + 1] := i_buf[i];
            Data[i * 3 + 2] := i_buf[i];
          end;
      16: for i := 0 to Width * Height - 1 do
        begin
          Data[3 * i] := PWordArray(i_buf)[i] and $1F shl $03;
          Data[3 * i + 1] := PWordArray(i_buf)[i] shr 5 and $1F shl 3;
          Data[3 * i + 2] := PWordArray(i_buf)[i] shr 10 and $1F shl 3;
        end;
      24, 32: Data := i_buf;
    end;
    if (ImageInfo and (1 shl 4)) <> 0 then Flip_H;
    if (ImageInfo and (1 shl 5)) = 0 then Flip_V;
  end;

  if TGA.BPP < 24 then
    FreeMem(i_buf);
  Result := True;
end;

// загрузка из файла

function LoadTGA(const FileName: PChar; var Width, Height, BPP: Integer; var Data: PByteArray): Boolean;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.CreateEx(FileName,fmOpenRead);
  Result := LoadImage(Stream, Width, Height, BPP, Data);
  Stream.Free;
end;

// загрузка из памяти

function LoadTGAmem(Mem: Pointer; Size: Integer; var Width, Height, BPP: Integer; var Data: PByteArray): Boolean;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.CreateEx(Mem,Size);
  Result := LoadImage(Stream, Width, Height, BPP, Data);
  Stream.Free;
end;

end.

