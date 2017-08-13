{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{                                                       }
{  Copyright (c) 1995-2002 Borland Software Corporation }
{                                                       }
{*******************************************************}

unit ASDUnit;

interface

uses
  Windows, Forms, Classes, SysUtils, AKlava,
  DelphiProtected, Graphics, OpenGL, FormsGL;

type
  TMessageType = (mtNone, mtSysTime, mtSysDataTime, mtProgTime, mtDir, mtLine);

  TLogSystem = class(TObject)
  private
    FFileName: string;
    FLog: TStringList;
    FSec: TSecundomer;
    procedure SetFileName(const Value: string);
  protected
    procedure AddText(const Format: string; const Args: array of const);
  public
    constructor Create(FileName: string);
    destructor Destroy; override;
    procedure AddLine(S: string; MessageType: TMessageType = mtNone);
    property FileName: string read FFileName write SetFileName;
  end;

  TASDEngine = class(TObject)
  private
    FLog: TLogSystem;
    FFormGL: TFormGL;
    FEscToExit: Boolean;
    procedure InitLog;
    procedure SaveLog;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  protected
    procedure Error(Msg: string);
    procedure AddLog(S: string; MessageType: TMessageType = mtNone);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ScreenOptions(Width, Height, BPP, Refresh: Integer; FullScreen,
      WaitVSync: Boolean);
    procedure InitGL;
    procedure Run;
    property Log: TLogSystem read FLog;
    property EscToExit: Boolean read FEscToExit write FEscToExit;
  end;

var
  ASDEngine: TASDEngine;
  FormGL: TFormGL;

implementation

uses ASDConst;

{ TLogSystem }

procedure TLogSystem.AddLine(S: string; MessageType: TMessageType);
const
  fsTime: string = '[%S] %S';
  fsDataTime: string = '[%S|%S] %S';
  fsDir: string = '--%S--';
  Kof: Real = 1000 * 60 * 60 * 24;
begin
  case MessageType of
    mtNone:
      FLog.Add(S);
    mtSysTime:
      AddText(fsTime, [TimeToStr(Time), S]);
    mtSysDataTime:
      AddText(fsDataTime, [DateToStr(Date), TimeToStr(Time), S]);
    mtProgTime:
      AddText(fsTime, [TimeToStr(FSec.Time / Kof), S]);
    mtDir:
      AddText(fsDir, [S]);
    mtLine:
      FLog.Add('----------------------');
  end;
end;

constructor TLogSystem.Create(FileName: string);
begin
  FFileName := FileName;
  if FFileName = '' then
    raise Exception.Create('File "' + FileName + '"not found');
  FLog := TStringList.Create;
  FSec := TSecundomer.Create;
  FSec.Start;
end;

destructor TLogSystem.Destroy;
begin
  FSec.Free;
  FLog.SaveToFile(FFileName);
  FLog.Free;
  inherited;
end;

procedure TLogSystem.AddText(const Format: string;
  const Args: array of const);
begin
  FLog.Add(SysUtils.Format(Format, Args));
end;

procedure TLogSystem.SetFileName(const Value: string);
begin
  if FFileName = '' then
    raise Exception.Create('File "' + FileName + '" not found');
  FFileName := Value;
end;

{ TASDEngine }

procedure TASDEngine.AddLog(S: string; MessageType: TMessageType);
begin
  FLog.AddLine(S, MessageType);
end;

constructor TASDEngine.Create;
begin
  InitLog;
  Application.Initialize;
  Application.CreateForm(TFormGL, FFormGL);
  FFormGL.Color := clBlack;
  FFormGL.Position := poScreenCenter;
  FFormGL.OnKeyDown := FormKeyDown;
  FormGL := FFormGL;
end;

procedure TASDEngine.FormKeyDown(Sender: TObject; var Key: Word; Shift:
  TShiftState);
begin
  if Key = VK_ESCAPE then
    FFormGL.Close;
end;

destructor TASDEngine.Destroy;
begin
  SaveLog;
  inherited;
end;

procedure TASDEngine.SaveLog;
begin
  with FLog do
  begin
    AddLog('Time Engine', mtProgTime);
    AddLog('Engine  Closed.', mtSysTime);
    Free;
  end;
end;

procedure TASDEngine.InitLog;
begin
  FLog := TLogSystem.Create('ASDEngine.Log');
  AddLog(cEngineName + ' ' + cEngineVERSION + ' Started...',
    mtSysDataTime);
  AddLog(cDirSysInfo, mtDir);
  AddLog(cCPU + GetCPUVendor);
  AddLog(GetCPUSpeed);
  AddLog(GetCPUProductivity);
  AddLog(GetAPIProductivity);
  AddLog(GetMemProductivity);
  AddLog('User : ' + GetUserNetName);
  AddLog(cDirEndInfo, mtDir);
end;

procedure TASDEngine.ScreenOptions(Width, Height, BPP, Refresh: Integer;
  FullScreen, WaitVSync: Boolean);
var
  Temp: DEVMODE;
begin
  if FullScreen then
  begin
    //FForm.WindowState := wsMaximized;
    FFormGL.BorderStyle := bsNone;
    FFormGL.Left := 0;
    FFormGL.Top := 0;
    AddLog(Format(cFullScreenMode, [Width, Height, BPP, Refresh]));
  end
  else
  begin
    FFormGL.BorderStyle := bsSingle;
    FFormGL.Position := poScreenCenter;
  end;
  FFormGL.Width := Width;
  FFormGL.Height := Height;

  if not FullScreen then
    Exit;
  EnumDisplaySettings(nil, 0, Temp);
  with Temp do
  begin
    dmSize := SizeOf(DEVMODE);
    dmPelsWidth := Width;
    dmPelsHeight := Height;
    dmBitsPerPel := BPP;
    dmDisplayFrequency := Refresh;
  end;
  if ChangeDisplaySettings(Temp, CDS_TEST or CDS_FULLSCREEN) <>
    DISP_CHANGE_SUCCESSFUL then
  begin
    Error('Невозможно переключится в полноэкранный режим!');
  end
  else
    ChangeDisplaySettings(Temp, CDS_FULLSCREEN);

  {if WaitVSync and (wglGetSwapIntervalEXT <> 1) then
    wglSwapIntervalEXT(1)
  else
    wglSwapIntervalEXT(0);}
end;

procedure TASDEngine.Run;
begin
  Application.Run;
end;

procedure TASDEngine.Error(Msg: string);
begin
  Exception.Create(Msg);
  AddLog(Msg, mtSysTime);
end;

procedure TASDEngine.InitGL;
  procedure InitSettings;
  begin
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_COLOR_MATERIAL);

    glShadeModel(GL_SMOOTH); // Enables Smooth Color Shading
    glClearDepth(1.0); // Depth Buffer Setup
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GREATER, 0);
    glEnable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
  end;
begin
  InitSettings;
end;

initialization
  ASDEngine := TASDEngine.Create;
finalization
  ASDEngine.Free;
end.

