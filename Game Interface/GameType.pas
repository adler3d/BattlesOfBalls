unit GameType;

interface
uses
  Windows;
type
  TGameRec = record
    UpdateTime, RenderTime: Real;
  end;

  PRect = ^TRect;
  TRect = packed record
    case Integer of
      0: (Left, Top, Right, Bottom: Longint);
      1: (TopLeft, BottomRight: TPoint);
  end;

  TRGB = record
    R, G, B: Byte;
  end;

  TRGBA = record
    R, G, B, A: Byte;
  end;

  TScreenMode = record
    X, Y, BPP, Freg: Integer;
  end;

  TWrapRGB = array[0..0] of TRGB;
  TWrapRGBA = array[0..0] of TRGBA;

const
  clRed: TRGBA = (R: 255; G: 0; B: 0; A: 255);
  clLime: TRGBA = (R: 0; G: 255; B: 0; A: 255);
  clBlue: TRGBA = (R: 0; G: 0; B: 255; A: 255);
  clWhite: TRGBA = (R: 255; G: 255; B: 255; A: 255);
  clBlack: TRGBA = (R: 0; G: 0; B: 0; A: 255);

  clYellow: TRGBA = (R: 255; G: 255; B: 0; A: 255);

function RGBA(R, G, B, A: Byte): TRGBA;
function RGB(R, G, B: Byte): TRGB;
function Rect(Left, Top, Right, Bottom: Integer): TRect;
function GetScreenMode: TScreenMode;

implementation
uses
  ASDHeader;

function Rect(Left, Top, Right, Bottom: Integer): TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Right;
  Result.Bottom := Bottom;
end;

function RGBA(R, G, B, A: Byte): TRGBA;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;

function RGB(R, G, B: Byte): TRGB;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
end;

function EqulRGBA(const V1, V2: TRGBA): Boolean;
begin
  Result := Integer(V1) = Integer(V2);
end;

function GetScreenMode: TScreenMode;
var
  DC: HDC;
begin
  DC := GetDC(Window.Handle);
  Result.X := GetDeviceCaps(DC, HORZRES);
  Result.Y := GetDeviceCaps(DC, VERTRES);
  Result.BPP := GetDeviceCaps(DC, BITSPIXEL);
  Result.Freg := GetDeviceCaps(DC, VREFRESH);
end;

end.

 