unit ASDHeader;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 14.10.07|>}
interface
uses
  ASDType, Windows;
type
  IASDObject = interface
    function ASDCountOBJ: Integer;
    function ASDObjectID: Integer;
    function ASDAllOBJ: Integer;
    function ASDName: string;
    procedure UnLoad;
  end;

  ILog = interface(IASDObject)
    function Create(FileName: PChar): Boolean;
    procedure Print(Sender: IASDObject; Text: PChar);
    function Msg(Caption, Text: PChar; ID: Cardinal = 0): Integer;
    procedure TimeStamp(Active: Boolean = True);
    procedure Flush(Active: Boolean = True);
    procedure Free;
  end;

  IWindow = interface(IASDObject)
    function Create(Caption: PChar; OnTop: Boolean = True): Boolean; overload;
    function Create(Handle: Cardinal): Boolean; overload;
    function Handle: Cardinal;
    procedure Caption(Text: PChar);
    function Width: Integer;
    function Height: Integer;
    function Mode(FullScreen: Boolean; W, H, BPP, Freq: Integer): Boolean;
    procedure Show(Minimized: Boolean);
    function Active: Boolean;
  end;

  IInput = interface(IASDObject)
    {private}
    function DownKey(Index: Byte): Boolean;
    function GetOnKeyDown: TKeyEvent;
    function GetOnKeyPress: TKeyPressEvent;
    procedure SetOnKeyDown(const Value: TKeyEvent);
    procedure SetOnKeyPress(const Value: TKeyPressEvent);
    procedure SetOnKeyUp(const Value: TKeyEvent);
    function GetOnKeyUp: TKeyEvent;
    {public}
    procedure AddKey(Key: Byte);
    procedure DelKey(Key: Byte);
    procedure Clear;
    procedure UpDate;
    property OnKeyDown: TKeyEvent read GetOnKeyDown write SetOnKeyDown;
    property OnKeyPress: TKeyPressEvent read GetOnKeyPress write SetOnKeyPress;
    property OnKeyUp: TKeyEvent read GetOnKeyUp write SetOnKeyUp;
    property Keys[Index: Byte]: Boolean read DownKey; default;
  end;

  IMouse = interface(IASDObject)
    {Private}
    procedure SetEnabled(Value: Boolean);
    procedure SetOnMouseDown(const Value: TMouseEvent);
    procedure SetOnMouseMove(const Value: TMouseMoveEvent);
    procedure SetOnMouseUp(const Value: TMouseEvent);
    function GetOnMouseDown: TMouseEvent;
    function GetOnMouseMove: TMouseMoveEvent;
    function GetOnMouseUp: TMouseEvent;
    function GetEnabled: Boolean;
    {Public}
    function Position: TPoint;
    function LastPosition: TPoint;
    function Vector(Button: TMouseButton): TPoint;
    function AbsVector(Button: TMouseButton): TPoint;
    function Down(Button: TMouseButton): Boolean;
    function IsMove: Boolean;
    procedure Update;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property OnMouseDown: TMouseEvent read GetOnMouseDown write SetOnMouseDown;
    property OnMouseUp: TMouseEvent read GetOnMouseUp write SetOnMouseUp;
    property OnMouseMove: TMouseMoveEvent read GetOnMouseMove write SetOnMouseMove;
  end;

  ITimer = interface(IASDObject)
    procedure Start;
    procedure Stop;
    function Time: Real;
    function Sec: Real;
    function Tick: Int64;
    function Activ: Boolean;
    function Freq: Int64;
    function TimeProc(Proc: TProcedure): Real;
  end;

  ICalcNPS = interface(IASDObject)
    function GetWaitTime: Real;
    procedure SetWaitTime(WaitTime: Real = 500);
    function GetMode: TCalcMode;
    procedure SetMode(const Value: TCalcMode);
    function NPS: Real;
    function MeanNPS: Real;
    function AllDateTime: TDateTime;
    function CountTick: Real;
    function AllTick: Integer;
    function AllTime: Real;
    procedure Reset;
    procedure Next;
    property WaitTime: Real read GetWaitTime write SetWaitTime;
    property Mode: TCalcMode read GetMode write SetMode;
  end;

  IOpenGL = interface(IASDObject)
    function FPS: Integer;
    procedure VSync(Active: Boolean); overload;
    function VSync: Boolean; overload;
    procedure Clear(Color: Boolean = True; Depth: Boolean = False; Stencil:
      Boolean = False);
    procedure Swap;
    procedure AntiAliasing(Samples: Integer); overload;
    function AntiAliasing: Integer; overload;
    procedure Set2D(x, y, w, h: Single);
    procedure Set3D(FOV, zNear, zFar: Single);
    procedure LightPos(ID: Integer; X, Y, Z: Single);
    procedure LightColor(ID: Integer; R, G, B: Single);
    function FontCreate(Name: PChar; Size: Integer): TFont;
    procedure FontFree(Font: TFont);
    procedure TextOut(Font: TFont; X, Y: Real; Text: PChar);
    function TextLen(Font: TFont; Text: PChar): Integer;
    function FontHeigth(Font: TFont): Integer;
    procedure Blend(BType: TBlendType);
    function ScreenShot(FileName: PChar): Boolean;
  end;

  ITexImage = interface(IASDObject)
    procedure Enable(Channel: Integer = 0);
    procedure Disable(Channel: Integer = 0);
    procedure RenderCopy(X, Y, W, H, Format: Integer; Level: Integer);
    procedure RenderBegin(Mode: TTexMode);
    procedure RenderEnd;
    procedure Filter(FilterType: Integer);
    function ID: Cardinal;
    function Width: Integer;
    function Height: Integer;
    function Group: Integer;
    function MipMap: Boolean;
    function Name: string;
  end;

  ITexture = interface(IASDObject)
    procedure Clear;
    function Make(Name: PChar; c, f, W, H: Integer; Data: Pointer; Clamp,
      MipMap: Boolean; Group: Integer): ITexImage;
    function LoadFromFile(FileName: PChar; Clamp: Boolean = False; MipMap:
      Boolean = True; Group: Integer = 0): ITexImage;
    function LoadFromMem(Name: PChar; Mem: Pointer; Size: Integer; Clamp: Boolean
      = False; MipMap: Boolean = True; Group: Integer = 0): ITexImage;
    function LoadDataFromFile(FileName: PChar; var W, H, BPP: Integer; var Data:
      Pointer): Boolean;
    function LoadDataFromMem(Name: PChar; Mem: Pointer; Size: Integer; var W, H,
      BPP: Integer; var Data: Pointer): Boolean;
    procedure Free(var Data: Pointer); overload;
    procedure Enable(ID: HTexture; Channel: Integer = 0);
    procedure Disable(Channel: Integer);
    procedure Filter(FilterType: Integer; Group: Integer);
    function RenderInit(TexSize: Integer): Boolean;
    function GetTex(const Name: string): ITexImage;
    function NewTex(const Name: string; Data: Pointer; C, F, W, H: Integer;
      Group: Integer = 0; Clamp: Boolean = False; MipMap: Boolean = True): ITexImage;
  end;

  ISound = interface(IASDObject)
    function Load(FileName: PChar; Group: Integer = 0): HSound; overload;
    function Load(Name: PChar; Mem: Pointer; Size: Integer; Group: Integer = 0):
      HSound; overload;
    function Free(ID: HSound): Boolean;
    function Play(ID: HSound; X, Y, Z: Single; Loop: Boolean = False): HChannel;
    procedure Stop(ID: HChannel);
    procedure Update_Begin(Group: Integer);
    procedure Update_End(Group: Integer);
    procedure Volume(Value: Integer);
    procedure Freq(Value: Integer);
    procedure Channel_Pos(ID: HChannel; X, Y, Z: Single);
    procedure Pos(X, Y, Z: Single);
    procedure Dir(dX, dY, dZ, uX, uY, uZ: Single);
    procedure Factor_Pan(Value: Single = 0.1);
    procedure Factor_Rolloff(Value: Single = 0.005);
    procedure PlayFile(FileName: PChar; Loop: Boolean = False);
    procedure StopFile;
  end;

  IList = interface(IASDObject)
    function Get(Index: Integer): Pointer;
    function GetCapacity: Integer;
    function GetCount: Integer;
    procedure Put(Index: Integer; Item: Pointer);
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);

    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function First: Pointer;
    function IndexOf(Item: Pointer): Integer;
    function Add(Item: Pointer): Integer;
    procedure Insert(Index: Integer; Item: Pointer);
    function Last: Pointer;
    function Remove(Item: Pointer): Integer;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: Pointer read Get write Put; default;
  end;

  IStream = interface(IASDObject)
    {private}
    function GetPosition: Integer;
    procedure SetPosition(const Pos: Integer);
    {protected}
    function GetSize: Integer;
    procedure SetSize(const NewSize: Integer);
    {public}
    function Read(var Buffer; Count: Integer): Integer;
    function Write(const Buffer; Count: Integer): Integer;
    function Seek(const Offset: Integer; Origin: TSeekOrigin = soBeginning):
      Integer;
    procedure ReadBuffer(var Buffer; Count: Integer);
    procedure WriteBuffer(const Buffer; Count: Integer);
    function CopyFrom(Source: IStream; Count: Integer): Integer;
    property Position: Integer read GetPosition write SetPosition;
    property Size: Integer read GetSize write SetSize;
    function Valid: Boolean;
  end;

  IHandleStream = interface(IStream)
    function Handle: HFile;
  end;

  IFileStream = interface(IHandleStream)
    function FileName: PChar;
  end;

  ICustomMemoryStream = interface(IStream)
    {protected}
    procedure SetPointer(Ptr: Pointer; Size: Longint);
    {public}
    procedure SaveToStream(Stream: IStream);
    procedure SaveToFile(const FileName: string);
    function Memory: Pointer;
  end;

  IMemoryStream = interface(ICustomMemoryStream)
    procedure Clear;
    procedure LoadFromStream(Stream: IStream);
    procedure LoadFromFile(const FileName: string);
  end;

  ITools = interface(IASDObject)
    function InitCalcNPS(WaitTime: Integer = 500): ICalcNPS;
    function InitTimer: ITimer;
    function InitFileStream(FileName: PChar; Mode: Word = 0): IFileStream;
    function InitList: IList;
    function InitQuickList: IList;
    function InitMemoryStream: IMemoryStream;
    function InitMemoryStreamEx(Memory: Pointer; Size: Integer): IMemoryStream;
  end;

  IASDEngine = interface(IASDObject)
    function Log: ILog;
    function Window: IWindow;
    function Input: IInput;
    function Mouse: IMouse;
    function OGL: IOpenGL;
    function Texture: ITexture;
    function Sound: ISound;
    function Tools: ITools;
    function Version: PChar;
    procedure RegProc(ID: Integer; Proc: Pointer);
    procedure ActiveUpdate(OnlyActive: Boolean);
    function GetTime: Real;
    procedure ResetTimer;
    procedure Update;
    procedure Render;
    procedure Quit;
    procedure Run(UPS: Integer);
  end;

var
  Engine: IASDEngine;
  Log: ILog;
  Window: IWindow;
  Input: IInput;
  Mouse: IMouse;
  OGL: IOpenGL;
  //ovbo : TVBO;
  Texture: ITexture;
  //ovfp : TVFP;
  Sound: ISound;
  Tools: ITools;

procedure InitEngine(out Engine: IASDEngine; LogFile: PChar);

implementation

uses ASDUtils;

procedure InitEngine; external 'ASDEngine.DLL';
var
  LogName: string;
initialization
  LogName := ChangeFileExt(ParamStr(0),'.htm');
  InitEngine(Engine, PChar(LogName));
  Log := Engine.Log;
  Sound := Engine.Sound;
  Input := Engine.Input;
  Mouse := Engine.Mouse;
  OGL := Engine.OGL;
  Texture := Engine.Texture;
  Window := Engine.Window;
  Tools := Engine.Tools;
end.

