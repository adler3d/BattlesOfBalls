unit GameTexture;

interface

uses
  Windows, ASDHeader, ASDUtils, ASDType, GameType {, Graphics};

type
  TAdlerTexFile = class(TObject)
  private
    FW: Integer;
    FH: Integer;
    FBPP: Integer;
    FTexMem: Pointer;
    FTexImage: ITexImage;
    FName: string;
    function BytesPerScanline(PixelsPerScanline, BitsPerPixel,
      Alignment: Integer): Longint;
    function GetScanLine(bmBits: Pointer; Row: Integer): Pointer;
  public
    procedure LoadFromSource(TexName, MaskName: string);
    function LoadFromFile(FileName: string): ITexImage;
    procedure SaveToFile(FileName: string);
    function MakeTexImage(Name: string): ITexImage;
    property TexImage: ITexImage read FTexImage;
    property W: Integer read FW;
    property H: Integer read FH;
    property BPP: Integer read FBPP;
    property Name: string read FName;
  end;

const
  GL_RGB8 = $8051;
  GL_RGBA8 = $8058;
  GL_BGR = $80E0;
  GL_BGRA = $80E1;

implementation

{ TAdlerTexFile }

procedure TAdlerTexFile.LoadFromSource(TexName, MaskName: string);
var
  I, X, Y: Integer;
  R: ^TRGBA;
  T, M: TRGBA;
  Temp: Pointer;
  StensilColor: TRGBA;
  LText, LMask: Pointer;
  TexMem: Pointer;
  MaskMem: Pointer;
begin
  if Pointer(FTexImage) <> FTexMem then
    Exit;
  Texture.LoadDataFromFile(PChar(MaskName), FW, FH, FBPP, MaskMem);
  if FBPP <> 32 then
    Exit;
  Texture.LoadDataFromFile(PChar(TexName), FW, FH, FBPP, TexMem);
  if FBPP <> 32 then
    Exit;
  GetMem(Temp, FH * FW * 4);
  I := 0;
  for Y := FH - 1 downto 0 do
  begin
    LText := GetScanLine(TexMem, Y);
    LMask := GetScanLine(MaskMem, Y);
    for X := 0 to FW - 1 do
    begin
      T := TWrapRGBA(LText^)[X];
      M := TWrapRGBA(LMask^)[X];
      R := @TWrapRGBA(Temp^)[I];
      R.R := T.R;
      R.G := T.G;
      R.B := T.B;
      R.A := (M.R + M.G + M.B) div 3;
      Inc(I);
    end;
  end;
  Texture.Free(MaskMem);
  Texture.Free(TexMem);
  FTexMem := Temp;
  FBPP := 32;
end;

function TAdlerTexFile.GetScanLine(bmBits: Pointer; Row: Integer): Pointer;
begin
  if FH > 0 then
    Row := FH - Row - 1;
  Integer(Result) := Integer(bmBits) +
    Row * BytesPerScanline(FW, FBPP, 32);
end;

function TAdlerTexFile.BytesPerScanline(PixelsPerScanline, BitsPerPixel,
  Alignment: Longint): Longint;
begin
  Dec(Alignment);
  Result := ((PixelsPerScanline * BitsPerPixel) + Alignment) and not Alignment;
  Result := Result div 8;
end;

function TAdlerTexFile.LoadFromFile(FileName: string): ITexImage;
var
  Stream: IFileStream;
  H: record
    Magic: string[3];
    W, H, BPP: Integer;
  end;
  Size: Integer;
  S: string;
begin
  Stream := Tools.InitFileStream(PChar(FileName), fmOpenRead);
  Stream.ReadBuffer(H, SizeOf(H));
  if H.Magic <> 'ATF' then
    Exit;
  FW := H.W;
  FH := H.H;
  Size := FW * FH * 4;
  FBPP := H.BPP;
  GetMem(FTexMem,Size);
  Stream.ReadBuffer(FTexMem^, Size);
  Result := MakeTexImage(FileName);
  FreeMem(FTexMem);
  FTexMem := nil;
  Stream.UnLoad;
end;

procedure TAdlerTexFile.SaveToFile(FileName: string);
var
  Stream: IFileStream;
  H: record
    Magic: string[3];
    W, H, BPP: Integer;
  end;
begin
  if (FTexImage <> nil) or (FTexMem = nil) then
    Exit;
  Stream := Tools.InitFileStream(PChar(FileName), fmCreate);
  H.Magic := 'ATF';
  H.W := FW;
  H.H := FH;
  H.BPP := FBPP;
  Stream.WriteBuffer(H, SizeOf(H));
  Stream.WriteBuffer(FTexMem^, FW * FH * 4);
  FreeMem(FTexMem);
  FTexMem := nil;
  FName := FileName;
  Stream.UnLoad;
end;

function TAdlerTexFile.MakeTexImage(Name: string): ITexImage;
begin
  if (FTexMem = nil) and (FTexImage <> nil) then
    Exit;
  FName := Name;
  FTexImage := Texture.NewTex(PChar(FName), FTexMem, GL_RGBA8, GL_BGRA, FW, FH,
    0, False, True);
  Result := FTexImage;
end;

end.

