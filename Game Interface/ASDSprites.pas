unit ASDSprites;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 08.07.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 08.07.07|>}
interface

uses
  Windows, ASDVector, ASDHeader, ASDUtils, GameType;
//{$D-}
type
  TString32 = string[32];

  TSprite = class;

  TSpriteEngine = class;

  TSpriteClass = class of TSprite;

  //  TSpriteMo

  TAccessObject = class(TObject)
  private
    FLockCount: Integer;
  public
    constructor Create;
    property LockCount: Integer read FLockCount;
    procedure Lock;
    procedure UnLock;
    procedure Free; virtual;
  end;

  TSprite = class(TAccessObject)
  private
    FEngine: TSpriteEngine;
    FParent: TSprite;
    FList: IList;
    FVisible: Boolean;
    FMoved: Boolean;
    FAllCount: Integer;
    FTag: Integer;
    FDeaded: boolean;
    FCaption: TString32;
    function GetCount: integer;
    function GetItems(Index: Integer): TSprite;
    procedure Remove(Sprite: TSprite);
    procedure Add(Sprite: TSprite); virtual;
  protected
    procedure DoMove; virtual;
    procedure DoDraw; virtual;
  public
    constructor Create(AParent: TSprite); virtual;
    procedure Free; override;
    procedure Draw; virtual;
    procedure Move; virtual;
    procedure Dead; virtual;
    procedure Clear;
    property Engine: TSpriteEngine read FEngine;
    property Visible: Boolean read FVisible write FVisible;
    property Moved: Boolean read FMoved write FMoved;
    property Tag: Integer read FTag write FTag;
    property Count: integer read GetCount;
    property Deaded: boolean read FDeaded;
    property Caption: TString32 read FCaption { write FCaption};
    property AllCount: Integer read FAllCount;
    property Parent: TSprite read FParent;
    property Items[Index: Integer]: TSprite read GetItems;
    default;
  end;

  {TSprite2D = class(TSprite)
  private
    FColor: TRGBA;
    FPosition: TVector;
    FVector: TVector;
  protected
    procedure DoMove; override;
  public
    constructor Create(AParent: TSprite); override;
    property Position: TVector read FPosition write FPosition;
    property X: Real read FPosition.X write FPosition.X;
    property Y: Real read FPosition.Y write FPosition.Y;
    property DX: Real read FVector.X write FVector.X;
    property DY: Real read FVector.Y write FVector.Y;
    property Vector: TVector read FVector write FVector;
  end;}

  TSpriteEngine = class(TSprite)
  private
    FDeadList: IList;
  public
    constructor Create(AParent: TSprite); override;
    destructor Destroy; override;
    procedure Dead; override;
  end;
  
function TestColision(const P1, P2: TVector; const R1, R2: Real): Boolean;

implementation

function TestColision(const P1, P2: TVector; const R1, R2: Real): Boolean;
var
  X, Y, R: Real;
begin
  //Result:=VectorMagnitude(VectorSub(A.FP,B.FP))<=(A.FR+B.FR);
  {X := A.FP.X-B.FP.X;
  Y := A.FP.Y-B.FP.Y;
  R := A.FR+B.FR;
  Result := (X*X+Y*Y)<=(R*R);}
  Result := ((P1.X - P2.X) * (P1.X - P2.X) + (P1.Y - P2.Y) * (P1.Y - P2.Y))
    <= ((R1 + R2) * (R1 + R2));
end;

{ TAccessObject }

constructor TAccessObject.Create;
begin
  FLockCount := 0;
end;

procedure TAccessObject.Free;
begin
  //Not Action
end;

procedure TAccessObject.Lock;
begin
  Inc(FLockCount);
end;

procedure TAccessObject.UnLock;
begin
  Dec(FLockCount);
  if FLockCount = 0 then
    inherited Free;
end;

{ TSprite }

procedure TSprite.Add(Sprite: TSprite);
begin
  if FList = nil then
  begin
    FList := Tools.InitQuickList;
  end;
  FList.Add(Sprite);
end;

constructor TSprite.Create(AParent: TSprite);
begin
  inherited Create;
  FParent := AParent;
  if FParent <> nil then
  begin
    FParent.Add(Self);
    if FParent is TSpriteEngine then
      FEngine := TSpriteEngine(FParent)
    else
      FEngine := FParent.Engine;
    Inc(FEngine.FAllCount);
    FCaption := ClassName + ' #' + IntToStr(FEngine.AllCount);
  end
  else
    FCaption := ClassName + ' Boss';
  FMoved := True;
  FVisible := True;
  Lock;
end;

procedure TSprite.Dead;
begin
  if (FEngine <> nil) and not FDeaded then
    FEngine.FDeadList.Add(Self);
  FDeaded := True;
end;

procedure TSprite.Clear;
begin
  while Count > 0 do
    Items[Count - 1].Free;
  if FList <> nil then
  begin
    FList.UnLoad;
    FList:=nil;
  end;
end;

procedure TSprite.Free;
begin
  Clear;
  if FParent <> nil then
  begin
    //Dec(FEngine.FAllCount);
    FParent.Remove(Self);
    FEngine.FDeadList.Remove(Self);
  end;
  UnLock;
end;

function TSprite.GetCount: integer;
begin
  if FList <> nil then
    Result := FList.Count
  else
    Result := 0;
end;

function TSprite.GetItems(Index: Integer): TSprite;
begin
  Result := FList[Index];
end;

procedure TSprite.Remove(Sprite: TSprite);
begin
  FList.Remove(Sprite);
  if FList.Count = 0 then
  begin
    FList.UnLoad;
    FList:=nil;
  end;
end;

procedure TSprite.Move;
var
  i: integer;
begin
  if FMoved then
  begin
    DoMove;
    for i := 0 to Count - 1 do
      Items[i].Move;
  end;
end;

procedure TSprite.DoDraw;
begin
end;

procedure TSprite.DoMove;
begin
end;

procedure TSprite.Draw;
var
  i: integer;
begin
  if FVisible then
  begin
    DoDraw;
    for I := 0 to Count - 1 do
      Items[I].Draw;
  end;
end;

(*{ TSprite2D }

constructor TSprite2D.Create(AParent: TSprite);
begin
  inherited;
  FVector := NulVector;
  FPosition := NulVector;
end;

procedure TSprite2D.DoMove;
begin
  FPosition := VectorAdd(FPosition, FVector);
end;*)

{ TSpriteEngine }

constructor TSpriteEngine.Create(AParent: TSprite);
begin
  inherited;
  FDeadList := Tools.InitQuickList;
end;

procedure TSpriteEngine.Dead;
var
  I, C: Integer;
begin
  {  while FDeadList.Count > 0 do
        TSprite(FDeadList[FDeadList.Count - 1]).Free;}
  C := FDeadList.Count - 1;
  for I := C downto 0 do
    TSprite(FDeadList[I]).Free;
end;

destructor TSpriteEngine.Destroy;
begin
  FDeadList.UnLoad;
  inherited;
end;

initialization

finalization

end.
