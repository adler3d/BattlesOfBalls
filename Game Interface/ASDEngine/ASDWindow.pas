unit ASDWindow;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 29.05.07|>}
interface

uses
  Windows, ASDUtils, Messages, MMSystem, OpenGL, ASDInterface,
  ASDInput, ASDType;

type
  TWndProc = function(hWnd: HWND; Msg: Cardinal; wParam: Integer; lParam:
    Integer): Integer; stdcall;

  TWindow = class(TASDObject, IWindow)
  private
    FReady: Boolean;
    FHandle: DWORD;
    FWidth: Integer;
    FHeight: Integer;
    FActive: Boolean;
    FMode: Boolean;
    FBPP: Integer;
    FFreq: Integer;
    FNoneX: Boolean;
    FDefProc: TWndProc;
  protected
    function RegisterWindow: Boolean;
    function MakeWindow(Caption: PChar; OnTop: Boolean): Boolean;
  public
    destructor Destroy; override;
    constructor CreateEx; override;
    function Create(Caption: PChar; OnTop: Boolean): Boolean; overload;
    function Create(Handle: Cardinal): Boolean; overload;
    function Handle: Cardinal;
    procedure Caption(Text: PChar);
    function Width: Integer;
    function Height: Integer;
    function Mode(FullScreen: Boolean; W, H, FBPP, FFreq: Integer): Boolean;
    procedure Show(Minimized: Boolean);
    function Active: Boolean;
    procedure AddLog(Text: string);
    procedure Restore;
    property DefProc: TWndProc read FDefProc;
    property Ready: Boolean read FReady;
    procedure UnLoad; override;
  end;

implementation
uses
  ASDEng, ASDSound;

const
  WND_TITLE = ENG_NAME;
  WND_CLASS = 'TForm' + ENG_NAME;

  //== Процедура обработки сообщений

function WndProc(hWnd: HWND; Msg: Cardinal; wParam: Integer; lParam: Integer):
  Integer; stdcall;
var
  S: string;
  d: TDevMode;
begin
  if (Msg = MM_MCINOTIFY) and (wParam = MCI_NOTIFY_SUCCESSFUL) then
    Sound.ReplayFile;

  if not Window.FNoneX then
    case Msg of
      WM_SYSKEYDOWN:
        case wParam of
          VK_RETURN: with Window do
              Mode(FMode, FWidth, FHeight, FBPP, FFreq);
          {VK_SPACE: with Input do
              MCapture(not m_cap);}
        end;
      WM_DESTROY:
        begin
          Engine.Quit;
          PostQuitMessage(0);
          Result := 0;
          Exit;
        end;

      // Активация/Деактивация главного окна
      WM_ACTIVATEAPP:
        begin
          // Сброс состояний клавиш
          Input.Clear;
          //Window.AddLog('<font color=Red>WM_ACTIVATEAPP</font>');
          //Window.AddLog('Active = <font color=#55FFFF>' + BoolArr[Window.FActive]
          //  + '</font>');
          // Активация / Деактивация окна
          with Window do
            if LOWORD(wParam) = WA_ACTIVE then
            begin
              FActive := True;
              //Window.AddLog('<font color=Lime>Activete</font>');
              // Если не в оконном режиме - переход в полноэкранный
              if not FMode then
              begin
                Show(False);
                Mode(True, FWidth, FHeight, FBPP, FFreq);
              end;
              if Engine.OnlyActive then
                Engine.ResetTimer;
            end
            else
            begin
              FActive := False;
              //Window.AddLog('<font color=Lime>Deactivete</font>');
              if not FMode then
              begin
                Show(True);
                Mode(False, FWidth, FHeight, FBPP, FFreq);
                FMode := False;
              end;
            end;
          Engine.OnActive;
        end;

      // смена графического режима
      WM_DISPLAYCHANGE:
        begin
          S := IntToStr(LOWORD(lParam)) + 'x' +
            IntToStr(HIWORD(lParam)) + 'x' +
            IntToStr(wParam);
          if EnumDisplaySettings(nil, Cardinal(-1), d) then
            S := S + 'x' + IntToStr(d.dmDisplayFrequency);
          Window.AddLog('Mode: ' + PChar(S));
        end;
      WM_MOUSEMOVE:
        begin
          Mouse.MouseMove(LOWORD(lParam), HIWORD(lParam));
        end;
      // клавиатура
      WM_KEYDOWN:
        begin
          Input.AddKey(wParam);
        end;
      WM_KEYUP:
        begin
          Input.DelKey(wParam);
        end;
      // мышь
      WM_LBUTTONUP: Mouse.MouseUp(mbLeft, LOWORD(lParam), HIWORD(lParam));
      WM_RBUTTONUP: Mouse.MouseUp(mbRight, LOWORD(lParam), HIWORD(lParam));
      WM_MBUTTONUP: Mouse.MouseUp(mbMiddle, LOWORD(lParam), HIWORD(lParam));
      WM_LBUTTONDOWN: Mouse.MouseDown(mbLeft, LOWORD(lParam), HIWORD(lParam));
      WM_RBUTTONDOWN: Mouse.MouseDown(mbRight, LOWORD(lParam), HIWORD(lParam));
      WM_MBUTTONDOWN: Mouse.MouseDown(mbMiddle, LOWORD(lParam), HIWORD(lParam));
      WM_MOUSEWHEEL: ; //oinp.SetKey(M_WHEEL, SmallInt(HIWORD(wParam)) div 120);
    end;
  // Стандартная обработка сообщения
  Result := Window.DefProc(hWnd, Msg, wParam, lParam);
  try
    if @Engine.ProcMessage <> nil then
      Engine.ProcMessage(Msg, wParam, lParam);
  except
    Engine.AddLog('Error in ProcMessage');
  end;
end;

destructor TWindow.Destroy;
begin
  inherited;
end;

function TWindow.Create(Caption: PChar; OnTop: Boolean): Boolean;
begin
  Result := True;
  if FReady then
    Exit;
  if FNoneX then
  begin
    AddLog('Setting main window');
    FDefProc := Pointer(SetWindowLong(FHandle, GWL_WNDPROC, Integer(@WndProc)));
    FReady := True;
  end
  else
  begin
    Result := False;
    OGL.GetPixelFormat; // Узнаём допустимое кол-во сэмплов под AntiAliasing
    AddLog('Create main window');
    //== Создание главного окна программы ==//
    // Регистрация класса главного окна
    if not RegisterWindow() then
    begin
      AddLog('Fatal Error "RegisterClassEx"');
      Exit;
    end;
    // Создаём окно
    if not MakeWindow(Caption, OnTop) then
    begin
      AddLog('Fatal Error "CreateWindoEx"');
      Exit;
    end;
  end;
  // инициализация графического ядра
  if not OGL.Init then
    Exit;
  // инициализация звука
  Sound.Init;
  // Показываем окно
  if not FNoneX then
  begin
    SetForegroundWindow(FHandle);
    ShowWindow(FHandle, SW_SHOW);
  end;
  UpdateWindow(FHandle);
  Restore;
  Result := True;
end;

function TWindow.Create(Handle: Cardinal): Boolean;
begin
  Result := False;
  if FReady then
    Exit;
  FNoneX := True;
  FHandle := Handle;
  Result := Self.Create(nil, False);
end;

function TWindow.Handle: Cardinal;
begin
  Result := FHandle;
end;

procedure TWindow.Caption(Text: PChar);
begin
  SetWindowText(FHandle, Text);
end;

function TWindow.Width: Integer;
var
  Rect: TRect;
begin
  GetClientRect(Handle, Rect);
  Result := Rect.Right;
end;

function TWindow.Height: Integer;
var
  Rect: TRect;
begin
  GetClientRect(Handle, Rect);
  Result := Rect.Bottom;
end;

function TWindow.Mode(FullScreen: Boolean; W, H, FBPP, FFreq: Integer): Boolean;

  function ModeStr: string;
  begin
    Result := IntToStr(W) + 'x' + IntToStr(H) + 'x' + IntToStr(FBPP) + 'x' +
      IntToStr(FFreq);
  end;

var
  dev: TDeviceMode;
  res: DWORD;
  bool: Boolean;
label
  ext;
begin
  Result := False;
  if FNoneX then
    Exit;
  if not FullScreen then
  begin
    ChangeDisplaySettings(_devicemodeA(nil^), CDS_FULLSCREEN);
    FMode := True;
    goto ext;
  end;
  FillChar(dev, SizeOf(dev), 0);
  dev.dmSize := SizeOf(dev);
  EnumDisplaySettings(nil, 0, dev);
  with dev do
  begin
    dmPelsWidth := W;
    dmPelsHeight := H;
    dmBitsPerPel := FBPP;
    dmDisplayFrequency := FFreq;
    dmFields := DM_BITSPERPEL or
      DM_PELSWIDTH or
      DM_PELSHEIGHT or
      DM_DISPLAYFREQUENCY;
    res := ChangeDisplaySettings(dev, CDS_TEST or CDS_FULLSCREEN);
    if res = DISP_CHANGE_SUCCESSFUL then
      ChangeDisplaySettings(dev, CDS_FULLSCREEN);
  end;

  if res <> DISP_CHANGE_SUCCESSFUL then
  begin
    bool := False;
    if FFreq > 0 then
      bool := Mode(FullScreen, W, H, FBPP, 0);
    if not bool then
    begin
      AddLog('Can''t set video mode: ' + ModeStr);
      Mode(False, W, H, self.FBPP, self.FFreq);
      FMode := True;
      Restore;
      Exit;
    end;
  end;

  FMode := False;
  ext:
  self.FBPP := FBPP;
  self.FFreq := FFreq;
  FWidth := W;
  FHeight := H;
  Restore;
  Result := True;
end;

procedure TWindow.Show(Minimized: Boolean);
begin
  if not FNoneX then
    if Minimized then
      ShowWindow(FHandle, SW_SHOWMINIMIZED)
    else
      ShowWindow(FHandle, SW_SHOWNORMAL);
end;

function TWindow.Active: Boolean;
begin
  Result := FActive;
end;

procedure TWindow.AddLog(Text: string);
begin
  Log.Print(Self, PChar(Text));
end;

procedure TWindow.Restore;
var
  Style: DWORD;
  Rect: TRect;
begin
  // изменение стиля окна в зависимости от режима работы
  if not FNoneX then
  begin
    if FMode then
      Style := WS_CAPTION
    else
      Style := WS_OVERLAPPED;
    SetWindowLong(FHandle, GWL_STYLE, Style or WS_VISIBLE);
    Rect.Left := 0;
    Rect.Top := 0;
    Rect.Right := FWidth;
    Rect.Bottom := FHeight;
    AdjustWindowRect(Rect, Style, False);
    with Rect do
      MoveWindow(FHandle, 0, 0, Right - Left, Bottom - Top, False);
    ShowWindow(FHandle, SW_SHOW);
  end;
  glViewport(0, 0, FWidth, FHeight);
end;

function TWindow.RegisterWindow: Boolean;
var
  wnd: TWndClassEx;
begin
  ZeroMemory(@wnd, SizeOf(wnd));
  with wnd do
  begin
    cbSize := SizeOf(wnd);
    lpfnWndProc := @WndProc;
    hCursor := LoadCursor(0, IDC_ARROW);
    lpszClassName := WND_CLASS;
  end;
  Result := RegisterClassEx(wnd) <> 0;
end;

function TWindow.MakeWindow(Caption: PChar; OnTop: Boolean): Boolean;
begin
  FDefProc := DefWindowProc;
  FHandle := CreateWindowEx(WS_EX_TOPMOST * Byte(OnTop = True), WND_CLASS,
    Caption, WS_POPUP,
    0, 0, 0, 0, 0, 0, 0, nil);
  FReady := FHandle <> 0;
  Result := FReady;
end;

constructor TWindow.CreateEx;
begin
  inherited CreateEx;
  FReady := False;
  FActive := False;
  FMode := True;
  FWidth := 640;
  FHeight := 480;
  FBPP := 16;
  FFreq := 60;
end;

procedure TWindow.UnLoad;
begin
  if FReady and (not FNoneX) then
  begin
    FReady := False;
    DestroyWindow(FHandle);
    AddLog('Destroy main window');
  end;
  inherited;
end;

end.

