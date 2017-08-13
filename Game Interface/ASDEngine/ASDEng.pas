unit ASDEng;
{<|Ìîäóëü áèáëèîòåêè ASDEngine|>}
{<|Äàòà ñîçäàíèÿ 29.05.07|>}
{<|Àâòîð Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Äàòà ïîñëåäíåãî èçìåíåíèÿ 6.07.07|>}
interface
uses
  Windows, OpenGL, ASDWindow, ASDInterface, ASDSound, ASDUtils,
  ASDType, ASDLog, ASDInput, ASDOpenGL, ASDTexture, ASDTools;

const
  ENG_NAME = 'ASDEngine';
  ENG_VER = '0.65';
type
  TASDEngine = class(TASDObject, IASDEngine)
  private
    FTerminate: Boolean;
    FOnlyActive: Boolean;
    FProcUpdate: TProcUpdate;
    FProcRender: TProcRender;
    FProcMessage: TProcMessage;
    FProcActive: TProcActive;
    FProcQuit: TProcQuit;
    FProcOverflow: TProcOverflow;
    FOldTime: Real;
    FUPS: Real;
  published
    function Log: ILog;
    function Window: IWindow;
    function Input: IInput;
    function Mouse: IMouse;
    function OGL: IOpenGL;
    //function VBuffer : IVBuffer;
    function Texture: ITexture;
    //function Shader: IShader;
    function Sound: ISound;
    function Tools: ITools;
    function Version: PChar;
    procedure RegProc(ID: Integer; Proc: Pointer);
    procedure ActiveUpdate(OnlyActive: Boolean);
    function GetTime: Real;
    procedure Run(UPS: Integer);
    procedure Update;
    procedure Render;
    procedure Quit;
  public
    constructor CreateEx; override;
    destructor Destroy; override;
    property Terminate: Boolean read FTerminate;
    property OnlyActive: Boolean read FOnlyActive write FOnlyActive;
    property ProcMessage: TProcMessage read FProcMessage;
    procedure ResetTimer;
    procedure OnActive;
    procedure AddLog(S: string);
    procedure UnLoad; override;
  end;

var
  Engine: TASDEngine;
  Log: TLog;
  Window: TWindow;
  Input: TInput;
  Mouse: TMouse;
  OGL: TOpenGL;
  //ovbo : TVBO;
  Texture: TTexture;
  //ovfp : TVFP;
  Sound: TSound;
  Tools: TTools;
implementation

{ TASDEngine }

constructor TASDEngine.CreateEx;
begin
  inherited CreateEx;
  ASDEng.Engine := ASDEng.Engine;
  ASDEng.Sound := TSound.CreateEx;
  ASDEng.Input := TInput.CreateEx;
  ASDEng.Mouse := TMouse.CreateEx;
  ASDEng.OGL := TOpenGL.CreateEx;
  ASDEng.Texture := TTexture.CreateEx;
  ASDEng.Window := TWindow.CreateEx;
  ASDEng.Tools := TTools.CreateEx;
end;

function TASDEngine.GetTime: Real;
begin
  Result := ASDUtils.GetTime;
end;

procedure TASDEngine.ActiveUpdate(OnlyActive: Boolean);
begin
  FOnlyActive := OnlyActive;
end;

function TASDEngine.Input: IInput;
begin
  Result := ASDEng.Input;
end;

function TASDEngine.Log: ILog;
begin
  Result := ASDEng.Log;
end;

function TASDEngine.Mouse: IMouse;
begin
  Result := ASDEng.Mouse;
end;

procedure TASDEngine.AddLog(S: string);
begin
  Log.Print(Self,PChar(S));
end;

function TASDEngine.OGL: IOpenGL;
begin
  Result := ASDEng.OGL;
end;

procedure TASDEngine.OnActive;
begin
  try
    if @FProcActive <> nil then
      FProcActive(Window.Active);
  except
    AddLog('Error in ProcActive');
  end;
end;

procedure TASDEngine.RegProc(ID: Integer; Proc: Pointer);
begin
  case ID of
    PROC_UPDATE: FProcUpdate := Proc;
    PROC_RENDER: FProcRender := Proc;
    PROC_MESSAGE: FProcMessage := Proc;
    PROC_ACTIVE: FProcActive := Proc;
    PROC_QUIT: FProcQuit := Proc;
    PROC_OVERFLOW: FProcOverflow := Proc;
  end;
end;

procedure TASDEngine.Render;
begin
  if FTerminate then
    Exit;
  try
    if @FProcRender<>nil then
      FProcRender;
  except
    AddLog('Error in ProcRender');
  end;
  OGL.Swap;
end;

procedure TASDEngine.ResetTimer;
begin
  FOldTime := GetTime;
end;

procedure TASDEngine.Run(UPS: Integer);
var
  Msg: TMsg;
  I, C: Integer;
  NewTime, DTime: Real;
  FOUT: Boolean;
begin
  AddLog('Run');

  FOldTime := GetTime;
  FUPS := UPS;
  //== ÃËÀÂÍÛÉ ÖÈÊË ÎÁÐÀÁÎÒÊÈ ÑÎÎÁÙÅÍÈÉ È ÒÀÉÌÈÍÃÀ ==//
  while not FTerminate do
  begin
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
    if (Window.Active and FOnlyActive) or (not FOnlyActive) then
    begin
      NewTime := GetTime;
      DTime := NewTime - FOldTime;
      C := Trunc(DTime * FUPS);
      if Assigned(FProcOverflow) then
      begin
        if C > 2 then
        begin
          FProcOverflow(SYS_UPS_OUT);
          FUPS := FUPS / 1.1;
          FOUT := True;
        end;
        if (C = 0)and(FOUT) then
        begin
          FUPS := FUPS * 1.1;
          if Round(FUPS) = UPS then
          begin
            FProcOverflow(SYS_UPS_IN);
            FOUT := False;
          end;
        end;
      end;
      for I := 1 to C do
      begin
        Update;
      end;
      FOldTime := NewTime - DTime + (C / FUPS);
      Render;
    end
    else
      WaitMessage;
  end;
  AddLog('Stop');
  try
    if @FProcQuit<>nil then
      FProcQuit;
  except
    AddLog('Error in ProcQuit');
  end;
  ASDEng.OGL.UnLoad;
  ASDEng.Texture.UnLoad;
end;

function TASDEngine.Sound: ISound;
begin
  Result := ASDEng.Sound;
end;

function TASDEngine.Texture: ITexture;
begin
  Result := ASDEng.Texture;
end;

procedure TASDEngine.Update;
begin
  if FTerminate then
    Exit;
  try
    if @FProcUpdate<>nil then
      FProcUpdate;
  except
    AddLog('Error in ProcUpdate');
  end;
  ASDEng.Sound.Update;
end;

function TASDEngine.Version: PChar;
begin
  Result := PChar(ENG_NAME + ' ' + ENG_VER);
end;

function TASDEngine.Window: IWindow;
begin
  Result := ASDEng.Window;
end;

procedure TASDEngine.Quit;
begin
  FTerminate := True;
end;

function TASDEngine.Tools: ITools;
begin
  Result := ASDEng.Tools;
end;

destructor TASDEngine.Destroy;
begin
  inherited;
end;

procedure TASDEngine.UnLoad;
begin
  ASDEng.Sound.UnLoad;
  ASDEng.Input.UnLoad;
  ASDEng.Mouse.UnLoad;
  ASDEng.Tools.UnLoad;
  ASDEng.Window.UnLoad;
  inherited;
end;

initialization

end.

