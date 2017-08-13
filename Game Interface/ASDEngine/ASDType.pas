unit ASDType;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 29.05.07|>}
interface
uses Windows;
{$D-}
type
  Int64Rec = packed record
    case Integer of
      0: (Lo, Hi: Cardinal);
      1: (Cardinals: array [0..1] of Cardinal);
      2: (Words: array [0..3] of Word);
      3: (Bytes: array [0..7] of Byte);
  end;

  TSeekOrigin = (soBeginning, soCurrent, soEnd);

  TSysCharSet = set of Char;

  TProcedure = procedure;

  TShiftState = set of (ssShift, ssAlt, ssCtrl,
    ssLeft, ssRight, ssMiddle, ssDouble);
    
  TMouseButton = (mbLeft, mbRight, mbMiddle);
  
  TCalcMode = (cmDef,cmAccum);

  TVector3D = record
    X,Y,Z:Single;
  end;

  HFile = DWORD;
  PByteArray = ^TByteArray;
  TByteArray = array[0..1023] of Byte;

  TRGB = record
    R, G, B: Byte;
  end;

  TRGBA = record
    R, G, B, A: Byte;
  end;

  TProcRender = procedure;
  TProcUpdate = procedure;
  TProcMessage = procedure(Msg: Cardinal; wP, lP: Integer);
  TProcActive = procedure(Active: Boolean);
  TProcQuit = procedure;
  TProcOverflow = procedure(Sys: Cardinal);

  TMouseEvent = procedure(Button: TMouseButton; Shift: TShiftState; X, Y: Real) of object;
  TMouseMoveEvent = procedure(Shift: TShiftState; X, Y: Real) of object;
  TKeyEvent = procedure(Key: Word; Shift: TShiftState) of object;
  TKeyPressEvent = procedure(Key: Char) of object;

  TFont = Cardinal;
  TBlendType = Integer;

  HTexture = Cardinal;
  TTexMode = Integer;

  TShader = Integer;
  TShAttrib = Integer;
  TShUniform = Integer;

  TVBOid = Integer;

  HSound = Integer;
  HChannel = Integer;
const
  PROC_UPDATE = 0;
  PROC_RENDER = 1;
  PROC_MESSAGE = 2;
  PROC_ACTIVE = 3;
  PROC_QUIT = 4;
  PROC_OVERFLOW = 5;

  SYS_UPS_OUT = 0;
  SYS_UPS_IN = 1;

  MSG_NONE = $00000000;
  MSG_ERROR = $00000010;
  MSG_INFO = $00000040;
  MSG_WARNING = $00000030;

  BT_NONE = 0;
  BT_SUB = 1;
  BT_ADD = 2;
  BT_MULT = 3;

  TM_COLOR = 1;
  TM_DEPTH = 2;

  FT_NONE = 0;
  FT_BILINEAR = 1;
  FT_TRILINEAR = 2;
  FT_ANISOTROPY = 3;

  ST_VERTEX = 0;
  ST_FRAGMENT = 1;

  VBO_INDEX = 0;
  VBO_VERTEX = 1;
  VBO_NORMAL = 2;
  VBO_COLOR = 3;
  VBO_TEXCOORD = 4;
  VBO_TEXCOORD1 = 4;
  VBO_TEXCOORD2 = 5;

  NULL_FILE = INVALID_HANDLE_VALUE;

const
  VK_0: Byte = 48;
  VK_1: Byte = 49;
  VK_2: Byte = 50;
  VK_3: Byte = 51;
  VK_4: Byte = 52;
  VK_5: Byte = 53;
  VK_6: Byte = 54;
  VK_7: Byte = 55;
  VK_8: Byte = 56;
  VK_9: Byte = 57;

  VK_A: Byte = 65;
  VK_B: Byte = 66;
  VK_C: Byte = 67;
  VK_D: Byte = 68;
  VK_E: Byte = 69;
  VK_F: Byte = 70;
  VK_G: Byte = 71;
  VK_H: Byte = 72;
  VK_I: Byte = 73;
  VK_J: Byte = 74;
  VK_K: Byte = 75;
  VK_L: Byte = 76;
  VK_M: Byte = 77;
  VK_N: Byte = 78;
  VK_O: Byte = 79;
  VK_P: Byte = 80;
  VK_Q: Byte = 81;
  VK_R: Byte = 82;
  VK_S: Byte = 83;
  VK_T: Byte = 84;
  VK_U: Byte = 85;
  VK_V: Byte = 86;
  VK_W: Byte = 87;
  VK_X: Byte = 88;
  VK_Y: Byte = 89;
  VK_Z: Byte = 90;

  VK_CONSOLE: Byte = 192;

{ File open modes }
  fmCreate = $FFFF;
  fmOpenRead       = $0000;
  fmOpenWrite      = $0001;
  fmOpenReadWrite  = $0002;

  fmShareCompat    = $0000 platform; // DOS compatibility mode is not portable
  fmShareExclusive = $0010;
  fmShareDenyWrite = $0020;
  fmShareDenyRead  = $0030 platform; // write-only not supported on all platforms
  fmShareDenyNone  = $0040;
{ File attribute constants }
  faReadOnly  = $00000001 platform;
  faHidden    = $00000002 platform;
  faSysFile   = $00000004 platform;
  faVolumeID  = $00000008 platform;
  faDirectory = $00000010;
  faArchive   = $00000020 platform;
  faSymLink   = $00000040 platform;
  faAnyFile   = $0000003F;

function MakeVector3D(AX,AY,AZ:Real):TVector3D;

implementation

function MakeVector3D(AX,AY,AZ:Real):TVector3D;
begin
  Result.X:=AX;
  Result.Y:=AY;
  Result.Z:=AZ;
end;

end.

