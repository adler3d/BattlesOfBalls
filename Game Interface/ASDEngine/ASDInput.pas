unit ASDInput;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 31.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 31.05.07|>}
interface
uses
  Windows, ASDType, ASDInterface, ASDUtils;

type

  TInput = class(TASDObject, IInput)
  private
    FKeySet: set of Byte;
    FOldKeySet: set of Byte;
    FOnKeyUp: TKeyEvent;
    FOnKeyDown: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    function DownKey(Index: Byte): Boolean;
    function GetOnKeyDown: TKeyEvent;
    function GetOnKeyPress: TKeyPressEvent;
    procedure SetOnKeyDown(const Value: TKeyEvent);
    procedure SetOnKeyPress(const Value: TKeyPressEvent);
    procedure SetOnKeyUp(const Value: TKeyEvent);
    function GetOnKeyUp: TKeyEvent;
  public
    constructor CreateEx; override;
    procedure AddKey(Key: Byte);
    procedure DelKey(Key: Byte);
    procedure Clear;
    procedure UpDate;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
    property Keys[Index: Byte]: Boolean read DownKey; default;
  end;

  TMouse = class(TASDObject, IMouse)
  private
    FDown, FOldDown: array[TMouseButton] of Boolean;
    FPosition: TPoint;
    FVector: array[TMouseButton] of TPoint;
    FAbsVector: array[TMouseButton] of TPoint;
    FLastPosition: TPoint;
    FEnabled: Boolean;
    FIsMove: Boolean;
    FOnMouseUp: TMouseEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    //FCapure: Boolean;
    function GetEnabled: Boolean;
    procedure SetEnabled(Value: Boolean);
    procedure SetOnMouseDown(const Value: TMouseEvent);
    procedure SetOnMouseMove(const Value: TMouseMoveEvent);
    procedure SetOnMouseUp(const Value: TMouseEvent);
    function GetOnMouseDown: TMouseEvent;
    function GetOnMouseMove: TMouseMoveEvent;
    function GetOnMouseUp: TMouseEvent;
  public
    constructor CreateEx; override;
    procedure MouseDown(AButton: TMouseButton; AX, AY: Integer);
    procedure MouseMove(AX, AY: Integer);
    procedure MouseUp(AButton: TMouseButton; AX, AY: Integer);
    function Position: TPoint;
    function LastPosition: TPoint;
    function Vector(Button: TMouseButton): TPoint;
    function AbsVector(Button: TMouseButton): TPoint;
    function Down(Button: TMouseButton): Boolean;
    function IsMove: Boolean;
    procedure Update;
    //procedure Capture(Value:Boolean);
    property Enabled: Boolean read FEnabled write FEnabled;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
  end;

implementation

uses ASDEng, Types;

{ TInput }

procedure TInput.AddKey(Key: Byte);
begin
  Include(FKeySet, Key);
end;

procedure TInput.Clear;
begin
  FKeySet := [];
  FOldKeySet := [];
end;

constructor TInput.CreateEx;
begin
  inherited CreateEx;
  Clear;
end;

procedure TInput.DelKey(Key: Byte);
begin
  Exclude(FKeySet, Key);
end;

function TInput.DownKey(Index: Byte): Boolean;
begin
  Result := Index in FKeySet;
end;

function TInput.GetOnKeyDown: TKeyEvent;
begin
  Result := FOnKeyDown;
end;

function TInput.GetOnKeyPress: TKeyPressEvent;
begin
  Result := FOnKeyPress;
end;

function TInput.GetOnKeyUp: TKeyEvent;
begin
  Result := FOnKeyUp;
end;

procedure TInput.SetOnKeyDown(const Value: TKeyEvent);
begin
  FOnKeyDown := Value;
end;

procedure TInput.SetOnKeyPress(const Value: TKeyPressEvent);
begin
  FOnKeyPress := Value;
end;

procedure TInput.SetOnKeyUp(const Value: TKeyEvent);
begin
  FOnKeyUp := Value;
end;

procedure TInput.UpDate;
var
  I: Byte;
  F: Boolean;
begin
  for I := 0 to 255 do
  begin
    F := I in FKeySet;
    if (I in FOldKeySet) xor F then
      if F then
      begin
        if Assigned(FOnKeyDown) then
          FOnKeyDown(I, []);
        Include(FOldKeySet, I);
      end
      else
      begin
        if Assigned(FOnKeyUp) then
          FOnKeyUp(I, []);
        Exclude(FOldKeySet, I);
      end;
  end;
end;

{ TMouse }

function TMouse.AbsVector(Button: TMouseButton): TPoint;
begin
  Result := FAbsVector[Button];
end;

{procedure TMouse.Capture(Value: Boolean);
begin
  FCapure:=Value;
  ShowCursor(FCapure);
end;}

constructor TMouse.CreateEx;
begin
  inherited CreateEx;
  FLastPosition := Point(0, 0);
  FPosition := Point(0, 0);

  FillChar(FVector, SizeOf(FVector), 0);
  FillChar(FAbsVector, SizeOf(FAbsVector), 0);
  FillChar(FDown, SizeOf(FDown), 0);

  FEnabled := True;
end;

function TMouse.Down(Button: TMouseButton): Boolean;
begin
  Result := FDown[Button];
end;

function TMouse.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TMouse.GetOnMouseDown: TMouseEvent;
begin
  Result := FOnMouseDown;
end;

function TMouse.GetOnMouseMove: TMouseMoveEvent;
begin
  Result := FOnMouseMove;
end;

function TMouse.GetOnMouseUp: TMouseEvent;
begin
  Result := FOnMouseUp;
end;

function TMouse.IsMove: Boolean;
begin
  Result := FIsMove;
end;

function TMouse.LastPosition: TPoint;
begin
  Result := FLastPosition;
end;

procedure TMouse.MouseDown(AButton: TMouseButton; AX, AY: Integer);
begin
  if (FEnabled and not FDown[AButton]) then
  begin
    FDown[AButton] := True;
    FPosition := Point(AX, AY);
  end;
end;

procedure TMouse.MouseMove(AX, AY: Integer);
  procedure DoMove(AButton: TMouseButton);
  begin
    with FVector[AButton] do
    begin
      X := AX - FPosition.X;
      Y := AY - FPosition.Y;
    end;
    with FAbsVector[AButton] do
    begin
      X := X + AX - FLastPosition.X;
      Y := Y + AY - FLastPosition.Y;
    end;
  end;
begin
  if not FEnabled then
    Exit;
  if (FDown[mbLeft]) then
    DoMove(mbLeft);
  if (FDown[mbRight]) then
    DoMove(mbRight);
  if (FDown[mbMiddle]) then
    DoMove(mbMiddle);
  FLastPosition := Point(AX, AY);
  //if FCapure then
  //SetCursorPos(AX,AY);
  FIsMove := True;
end;

procedure TMouse.MouseUp(AButton: TMouseButton; AX, AY: Integer);
begin
  if FDown[AButton] and (Enabled) then
  begin
    FDown[AButton] := False;
    FPosition := Point(AX, AY);
    FVector[AButton] := Point(0, 0);
  end;
end;

function TMouse.Position: TPoint;
begin
  Result := FPosition;
end;

procedure TMouse.SetEnabled(Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TMouse.SetOnMouseDown(const Value: TMouseEvent);
begin
  FOnMouseDown := Value;
end;

procedure TMouse.SetOnMouseMove(const Value: TMouseMoveEvent);
begin
  FOnMouseMove := Value;
end;

procedure TMouse.SetOnMouseUp(const Value: TMouseEvent);
begin
  FOnMouseUp := Value;
end;

procedure TMouse.Update;
var
  I: Byte;
  F: Boolean;
  B: TMouseButton;
begin
//  SetCursorPos(FLastPosition.X,FLastPosition.Y);
  for I := 0 to 2 do
  begin
    B := TMouseButton(I);
    F := FDown[B];
    if FOldDown[B] xor F then
    begin
      if F then
      begin
        if Assigned(FOnMouseDown) then
          FOnMouseDown(B, [], FPosition.X, FPosition.Y);
      end
      else
      begin
        if Assigned(FOnMouseUp) then
          FOnMouseUp(B, [], FPosition.X, FPosition.Y);
      end;
      FOldDown[B] := F;
    end;
  end;
  if (IsMove) and Assigned(FOnMouseMove) then
    FOnMouseMove([], FLastPosition.X, FLastPosition.Y);
end;

function TMouse.Vector(Button: TMouseButton): TPoint;
begin
  Result := FVector[Button];
end;

end.

