unit ASDClasses;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 5.07.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 5.07.07|>}
interface

uses Windows, ASDInterface, ASDType, ASDUtils;

const
  { Maximum TList size }

  MaxListSize = Maxint div 16;

  { TStream seek origins }

const
  { TFileStream create mode }

  fmCreate = $FFFF;

  { TParser special tokens }

  toEOF = Char(0);
  toSymbol = Char(1);
  toString = Char(2);
  toInteger = Char(3);
  toFloat = Char(4);
  toWString = Char(5);

  {!! Moved here from menus.pas !!}
  { TShortCut special values }

  scShift = $2000;
  scCtrl = $4000;
  scAlt = $8000;
  scNone = 0;

type
  TToolObject = class(TASDObject)
  public
    constructor CreateEx; override;
  end;

  { Text alignment types }

  TAlignment = (taLeftJustify, taRightJustify, taCenter);
  TLeftRight = taLeftJustify..taRightJustify;
  TBiDiMode = (bdLeftToRight, bdRightToLeft, bdRightToLeftNoAlign,
    bdRightToLeftReadingOnly);

  { Types used by standard events }

  TShiftState = set of (ssShift, ssAlt, ssCtrl,
    ssLeft, ssRight, ssMiddle, ssDouble);

  THelpContext = -MaxLongint..MaxLongint;
  THelpType = (htKeyword, htContext);

  {!! Moved here from menus.pas !!}
  TShortCut = Low(Word)..High(Word);

  { Standard events }

  TNotifyEvent = procedure(Sender: TObject) of object;
  TGetStrProc = procedure(const S: string) of object;

  { Duplicate management }

  TDuplicates = (dupIgnore, dupAccept, dupError);

  { Forward class declarations }

  TStream = class;

  { TTimer }

  TTimer = class(TToolObject, ITimer)
  private
    FActiv: Boolean;
    FEndTime: Int64;
    FStartTime: Int64;
    FFreq: Int64;
  public
    function Time: Real;
    function Sec: Real;
    function Tick: Int64;
    function Activ: Boolean;
    function Freq: Int64;
  public
    constructor CreateEx; override;
    procedure Start; virtual;
    procedure Stop; virtual;
    function TimeProc(Proc: TProcedure): Real;
  end;

  { TCalcNPS }

  TCalcNPS = class(TTimer, ICalcNPS)
  private
    FCountTick: Real;
    FWaitTime: Real;
    FLastCount: Real;
    FLastTime: Real;
    FAllTick: Integer;
    FAllTime: Real;
    FMode: TCalcMode;
    function GetWaitTime: Real;
    procedure SetWaitTime(WaitTime: Real = 500);
    function GetMode: TCalcMode;
    procedure SetMode(const Value: TCalcMode);
  public
    constructor CreateEx(WaitTime: Real = 500); virtual;
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

  { TList class }

  PPointerList = ^TPointerList;
  TPointerList = array[0..MaxListSize - 1] of Pointer;
  TListSortCompare = function(Item1, Item2: Pointer): Integer;
  TListNotification = (lnAdded, lnExtracted, lnDeleted);

  // these operators are used in Assign and go beyond simply copying
  //   laCopy = dest becomes a copy of the source
  //   laAnd  = intersection of the two lists
  //   laOr   = union of the two lists
  //   laXor  = only those not in both lists
  // the last two operators can actually be thought of as binary operators but
  // their implementation has been optimized over their binary equivalent.
  //   laSrcUnique  = only those unique to source (same as laAnd followed by laXor)
  //   laDestUnique = only those unique to dest   (same as laOr followed by laXor)
  TListAssignOp = (laCopy, laAnd, laOr, laXor, laSrcUnique, laDestUnique);

  TList = class(TToolObject, IList)
  private
    FList: PPointerList;
    FCount: Integer;
    FCapacity: Integer;
  protected
    function Get(Index: Integer): Pointer;
    procedure Grow; virtual;
    procedure Put(Index: Integer; Item: Pointer);
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
    function GetCapacity: Integer;
    function GetCount: Integer;
  public
    destructor Destroy; override;
    function Add(Item: Pointer): Integer;
    procedure Clear; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Exchange(Index1, Index2: Integer);
    function Expand: TList;
    function Extract(Item: Pointer): Pointer;
    function First: Pointer;
    function IndexOf(Item: Pointer): Integer;
    procedure Insert(Index: Integer; Item: Pointer);
    function Last: Pointer;
    procedure Move(CurIndex, NewIndex: Integer);
    function Remove(Item: Pointer): Integer;
    procedure Pack;
    procedure Sort(Compare: TListSortCompare);
    procedure Assign(ListA: TList; AOperator: TListAssignOp = laCopy; ListB:
      TList = nil);
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read Get write Put; default;
    property List: PPointerList read FList;
  end;

  TQuickList = class(TList)
    procedure Delete(Index: Integer); override;
  end;

  { TStream abstract class }

  TStream = class(TToolObject, IStream)
  private
    function GetPosition: Integer;
    procedure SetPosition(const Pos: Integer);
  protected
    function GetSize: Integer; virtual;
    procedure SetSize(const NewSize: Integer); virtual;
  public
    function Read(var Buffer; Count: Longint): Longint; virtual; abstract;
    function Write(const Buffer; Count: Longint): Longint; virtual; abstract;
    function Seek(const Offset: Integer; Origin: TSeekOrigin = soBeginning):
      Integer; virtual;
    procedure ReadBuffer(var Buffer; Count: Longint);
    procedure WriteBuffer(const Buffer; Count: Longint);
    function CopyFrom(Source: IStream; Count: Integer): Integer;
    function Valid: Boolean;
    property Position: Integer read GetPosition write SetPosition;
    property Size: Integer read GetSize write SetSize;
  end;

  { THandleStream class }

  THandleStream = class(TStream, IHandleStream)
  protected
    FHandle: HFile;
    procedure SetSize(const NewSize: Integer); override;
  public
    constructor CreateEx(AHandle: Integer);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Integer; Origin: TSeekOrigin = soBeginning):
      Integer; override;
    function Handle: HFile;
  end;

  { TFileStream class }

  TFileStream = class(THandleStream, IFileStream)
  private
    FFileName: string;
  public
    constructor CreateEx(const FileName: string; Mode: Word);
    destructor Destroy; override;
    function FileName: PChar;
    procedure UnLoad; override;
  end;

  { TCustomMemoryStream abstract class }

  TCustomMemoryStream = class(TStream, ICustomMemoryStream)
  private
    FMemory: Pointer;
    FSize, FPosition: Integer;
  protected
    procedure SetPointer(Ptr: Pointer; Size: Integer);
  public
    function Read(var Buffer; Count: Longint): Integer; override;
    function Seek(const Offset: Integer; Origin: TSeekOrigin = soBeginning):
      Integer; override;
    procedure SaveToStream(Stream: IStream);
    procedure SaveToFile(const FileName: string);
    function Memory: Pointer;
  end;

  { TMemoryStream }

  TMemoryStream = class(TCustomMemoryStream, IMemoryStream)
  private
    FCapacity: Integer;
    FNone: Boolean;
    procedure SetCapacity(NewCapacity: Integer);
  protected
    function Realloc(var NewCapacity: Integer): Pointer; virtual;
    property Capacity: Integer read FCapacity write SetCapacity;
  public
    constructor CreateEx; overload; override;
    constructor CreateEx(Memory: Pointer; Size: Integer); overload;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromStream(Stream: IStream);
    procedure LoadFromFile(const FileName: string);
    procedure SetSize(const NewSize: Integer); override;
    function Write(const Buffer; Count: Integer): Integer; override;
  end;

  //{ TStringStream }

  {TStringStream = class(TStream, IStringStream)
  private
    FDataString: string;
    FPosition: Integer;
    function GetDataString: PChar;
  protected
    procedure SetSize(const NewSize: Integer); override;
  public
    constructor Create(const AString: string);
    function Read(var Buffer; Count: Integer): Integer; override;
    function ReadString(Count: Integer): PChar;
    function Seek(const Offset: Integer; Origin: TSeekOrigin = soBeginning):
      Integer; override;
    function Write(const Buffer; Count: Integer): Integer; override;
    procedure WriteString(const AString: PChar);
    property DataString: PChar read GetDataString;
  end; }

  { TResourceStream }

  TResourceStream = class(TCustomMemoryStream)
  private
    HResInfo: THandle;
    HGlobal: THandle;
    procedure Initialize(Instance: THandle; Name, ResType: PChar);
  public
    constructor Create(Instance: THandle; const ResName: string; ResType:
      PChar);
    constructor CreateFromID(Instance: THandle; ResID: Integer; ResType: PChar);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

procedure RaiseError(obj: IASDObject; Msg: string);

implementation

uses ASDEng;

procedure RaiseError(obj: IASDObject; Msg: string);
begin
  Log.Print(obj, PChar(Msg));
end;

{ TTimer }

function TTimer.Activ: Boolean;
begin
  Result := FActiv;
end;

constructor TTimer.CreateEx;
begin
  inherited CreateEx;
  FActiv := False;
  QueryPerformanceFrequency(FFreq);
end;

function TTimer.Freq: Int64;
begin
  Result := FFreq;
end;

function TTimer.Sec: Real;
begin
  if FActiv then
    QueryPerformanceCounter(FEndTime);
  Result := (FEndTime - FStartTime) / Freq;
end;

function TTimer.Tick: Int64;
begin
  if FActiv then
    QueryPerformanceCounter(FEndTime);
  Result := (FEndTime - FStartTime);
end;

function TTimer.Time: Real;
begin
  if FActiv then
    QueryPerformanceCounter(FEndTime);
  Result := (FEndTime - FStartTime) * 1000 / Freq;
end;

procedure TTimer.Start;
begin
  FActiv := True;
  QueryPerformanceCounter(FStartTime);
end;

procedure TTimer.Stop;
begin
  FActiv := False;
  QueryPerformanceCounter(FEndTime);
end;

function TTimer.TimeProc(Proc: TProcedure): Real;
var
  ST, ET: Int64;
begin
  QueryPerformanceCounter(ST);
  Proc;
  QueryPerformanceCounter(ET);
  Result := (ET - ST) / FFreq;
end;

{ TCalcFPS }

function TCalcNPS.AllDateTime: TDateTime;
const
  mSecInDay: Real = 24 * 60 * 60 * 1000;
begin
  Result := FAllTime / mSecInDay;
end;

function TCalcNPS.AllTick: Integer;
begin
  Result := FAllTick;
end;

function TCalcNPS.AllTime: Real;
begin
  Result := FAllTime;
end;

function TCalcNPS.CountTick: Real;
begin
  Result := FCountTick;
end;

constructor TCalcNPS.CreateEx(WaitTime: Real);
begin
  inherited CreateEx;
  FWaitTime := WaitTime;
  FAllTick := 0;
  FAllTime := 0;
end;

function TCalcNPS.NPS: Real;
begin
  if FLastCount = 0 then
  begin
    if FCountTick > 0 then
    begin
      Result := (FCountTick * 1000) / Self.Time;
      Exit;
    end;
    if not Activ then
      Reset;
    Result := 0;
    Exit;
  end;
  Result := (FLastCount * 1000) / FLastTime;
end;

function TCalcNPS.MeanNPS: Real;
begin
  if FAllTime = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := (FAllTick * 1000) / FAllTime;
end;

procedure TCalcNPS.Next;
begin
  Inc(FAllTick);
  if FMode = cmDef then
  begin
    FCountTick := FCountTick + 1;
    if (Self.Time > FWaitTime) or not Activ then
      Reset;
  end
  else if FMode = cmAccum then
  begin
    FCountTick := FCountTick + 1;
    FLastCount := FCountTick;
    FLastTime := FWaitTime;
    FCountTick := FCountTick - FCountTick*(Time/FWaitTime);
    FStartTime:=FStartTime+Tick;
  end;
end;

procedure TCalcNPS.Reset;
begin
  if FActiv then
    Stop;
  FLastTime := Time;
  FAllTime := FAllTime + FLastTime;
  FLastCount := FCountTick;
  FCountTick := 0;
  Start;
end;

procedure TCalcNPS.SetWaitTime(WaitTime: Real);
begin
  FWaitTime := WaitTime;
  Reset;
end;

function TCalcNPS.GetWaitTime: Real;
begin
  Result := FWaitTime;
end;

function TCalcNPS.GetMode: TCalcMode;
begin
  Result := FMode;
end;

procedure TCalcNPS.SetMode(const Value: TCalcMode);
begin
  FMode := Value;
end;

{ TList }

destructor TList.Destroy;
begin
  Clear;
end;

function TList.Add(Item: Pointer): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  FList^[Result] := Item;
  Inc(FCount);
end;

procedure TList.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

procedure TList.Delete(Index: Integer);
var
  Temp: Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index) + ')');
    Exit;
  end;
  Temp := Items[Index];
  Dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Pointer));
end;

procedure TList.Exchange(Index1, Index2: Integer);
var
  Item: Pointer;
begin
  if (Index1 < 0) or (Index1 >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index1) + ')');
    Exit;
  end;
  if (Index2 < 0) or (Index2 >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index2) + ')');
    Exit;
  end;
  Item := FList^[Index1];
  FList^[Index1] := FList^[Index2];
  FList^[Index2] := Item;
end;

function TList.Expand: TList;
begin
  if FCount = FCapacity then
    Grow;
  Result := Self;
end;

function TList.First: Pointer;
begin
  Result := Get(0);
end;

function TList.Get(Index: Integer): Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index) + ')');
    Exit;
  end;
  Result := FList^[Index];
end;

procedure TList.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else if FCapacity > 8 then
    Delta := 16
  else
    Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

function TList.IndexOf(Item: Pointer): Integer;
begin
  Result := 0;
  while (Result < FCount) and (FList^[Result] <> Item) do
    Inc(Result);
  if Result = FCount then
    Result := -1;
end;

procedure TList.Insert(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index > FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index) + ')');
    Exit;
  end;
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(Pointer));
  FList^[Index] := Item;
  Inc(FCount);
end;

function TList.Last: Pointer;
begin
  Result := Get(FCount - 1);
end;

procedure TList.Move(CurIndex, NewIndex: Integer);
var
  Item: Pointer;
begin
  if CurIndex <> NewIndex then
  begin
    if (NewIndex < 0) or (NewIndex >= FCount) then
    begin
      RaiseError(Self, 'List index out of bounds (' + IntToStr(NewIndex) + ')');
      Exit;
    end;
    Item := Get(CurIndex);
    FList^[CurIndex] := nil;
    Delete(CurIndex);
    Insert(NewIndex, nil);
    FList^[NewIndex] := Item;
  end;
end;

procedure TList.Put(Index: Integer; Item: Pointer);
var
  Temp: Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index) + ')');
    Exit;
  end;
  if Item <> FList^[Index] then
  begin
    Temp := FList^[Index];
    FList^[Index] := Item;
  end;
end;

function TList.Remove(Item: Pointer): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TList.Pack;
var
  I: Integer;
begin
  for I := FCount - 1 downto 0 do
    if Items[I] = nil then
      Delete(I);
end;

procedure TList.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then
  begin
    RaiseError(Self, 'List capacity out of bounds (' + IntToStr(NewCapacity) +
      ')');
    Exit;
  end;
  if NewCapacity <> FCapacity then
  begin
    ReallocMem(FList, NewCapacity * SizeOf(Pointer));
    FCapacity := NewCapacity;
  end;
end;

procedure TList.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxListSize) then
  begin
    RaiseError(Self, 'List count out of bounds (' + IntToStr(NewCount) + ')');
    Exit;
  end;
  if NewCount > FCapacity then
    SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(Pointer), 0)
  else
    for I := FCount - 1 downto NewCount do
      Delete(I);
  FCount := NewCount;
end;

procedure QuickSort(SortList: PPointerList; L, R: Integer;
  SCompare: TListSortCompare);
var
  I, J: Integer;
  P, T: Pointer;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SCompare(SortList^[I], P) < 0 do
        Inc(I);
      while SCompare(SortList^[J], P) > 0 do
        Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure TList.Sort(Compare: TListSortCompare);
begin
  if (FList <> nil) and (Count > 0) then
    QuickSort(FList, 0, Count - 1, Compare);
end;

function TList.Extract(Item: Pointer): Pointer;
var
  I: Integer;
begin
  Result := nil;
  I := IndexOf(Item);
  if I >= 0 then
  begin
    Result := Item;
    FList^[I] := nil;
    Delete(I);
  end;
end;

procedure TList.Assign(ListA: TList; AOperator: TListAssignOp; ListB: TList);
var
  I: Integer;
  LTemp, LSource: TList;
begin
  // ListB given?
  if ListB <> nil then
  begin
    LSource := ListB;
    Assign(ListA);
  end
  else
    LSource := ListA;

  // on with the show
  case AOperator of

    // 12345, 346 = 346 : only those in the new list
    laCopy:
      begin
        Clear;
        Capacity := LSource.Capacity;
        for I := 0 to LSource.Count - 1 do
          Add(LSource[I]);
      end;

    // 12345, 346 = 34 : intersection of the two lists
    laAnd:
      for I := Count - 1 downto 0 do
        if LSource.IndexOf(Items[I]) = -1 then
          Delete(I);

    // 12345, 346 = 123456 : union of the two lists
    laOr:
      for I := 0 to LSource.Count - 1 do
        if IndexOf(LSource[I]) = -1 then
          Add(LSource[I]);

    // 12345, 346 = 1256 : only those not in both lists
    laXor:
      begin
        LTemp := TList.Create; // Temp holder of 4 byte values
        try
          LTemp.Capacity := LSource.Count;
          for I := 0 to LSource.Count - 1 do
            if IndexOf(LSource[I]) = -1 then
              LTemp.Add(LSource[I]);
          for I := Count - 1 downto 0 do
            if LSource.IndexOf(Items[I]) <> -1 then
              Delete(I);
          I := Count + LTemp.Count;
          if Capacity < I then
            Capacity := I;
          for I := 0 to LTemp.Count - 1 do
            Add(LTemp[I]);
        finally
          LTemp.Free;
        end;
      end;

    // 12345, 346 = 125 : only those unique to source
    laSrcUnique:
      for I := Count - 1 downto 0 do
        if LSource.IndexOf(Items[I]) <> -1 then
          Delete(I);

    // 12345, 346 = 6 : only those unique to dest
    laDestUnique:
      begin
        LTemp := TList.Create;
        try
          LTemp.Capacity := LSource.Count;
          for I := LSource.Count - 1 downto 0 do
            if IndexOf(LSource[I]) = -1 then
              LTemp.Add(LSource[I]);
          Assign(LTemp);
        finally
          LTemp.Free;
        end;
      end;
  end;
end;

function TList.GetCapacity: Integer;
begin
  Result := FCapacity;
end;

function TList.GetCount: Integer;
begin
  Result := FCount;
end;

{ TQuickList }

procedure TQuickList.Delete(Index: Integer);
var
  Temp: Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RaiseError(Self, 'List index out of bounds (' + IntToStr(Index) + ')');
    Exit;
  end;
  Temp := Items[Index];
  FList^[Index] := FList^[FCount - 1];
  Dec(FCount);
end;

{ TStream }

function TStream.GetPosition: Integer;
begin
  Result := Seek(0, soCurrent);
end;

procedure TStream.SetPosition(const Pos: Integer);
begin
  Seek(Pos, soBeginning);
end;

function TStream.GetSize: Integer;
var
  Pos: Integer;
begin
  Pos := Seek(0, soCurrent);
  Result := Seek(0, soEnd);
  Seek(Pos, soBeginning);
end;

function TStream.Seek(const Offset: Integer; Origin: TSeekOrigin): Integer;
  procedure RaiseException;
  begin
    RaiseError(Self, Classname + '.Seek not implemented');
    Exit;
  end;
type
  TSeek64 = function(const Offset: Integer; Origin: TSeekOrigin): Integer of
    object;
var
  Impl: TSeek64;
  Base: TSeek64;
  ClassTStream: TClass;
begin
  Impl := Seek;
  ClassTStream := Self.ClassType;
  while (ClassTStream <> nil) and (ClassTStream <> TStream) do
    ClassTStream := ClassTStream.ClassParent;
  if ClassTStream = nil then
    RaiseException;
  Base := TStream(@ClassTStream).Seek;
  if TMethod(Impl).Code = TMethod(Base).Code then
    RaiseException;
  Result := Seek(Integer(Offset), TSeekOrigin(Origin));
end;

procedure TStream.ReadBuffer(var Buffer; Count: Longint);
begin
  if (Count <> 0) and (Read(Buffer, Count) <> Count) then
  begin
    RaiseError(Self, 'Stream read error');
    Exit;
  end;
end;

procedure TStream.WriteBuffer(const Buffer; Count: Longint);
begin
  if (Count <> 0) and (Write(Buffer, Count) <> Count) then
  begin
    RaiseError(Self, 'Stream write error');
    Exit;
  end;
end;

function TStream.CopyFrom(Source: IStream; Count: Integer): Integer;
const
  MaxBufSize = $F000;
var
  BufSize, N: Integer;
  Buffer: PChar;
begin
  if Count = 0 then
  begin
    Source.Position := 0;
    Count := Source.Size;
  end;
  Result := Count;
  if Count > MaxBufSize then
    BufSize := MaxBufSize
  else
    BufSize := Count;
  GetMem(Buffer, BufSize);
  try
    while Count <> 0 do
    begin
      if Count > BufSize then
        N := BufSize
      else
        N := Count;
      Source.ReadBuffer(Buffer^, N);
      WriteBuffer(Buffer^, N);
      Dec(Count, N);
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;

procedure TStream.SetSize(const NewSize: Integer);
begin

end;

function TStream.Valid: Boolean;
begin

end;

{ THandleStream }

constructor THandleStream.CreateEx(AHandle: Integer);
begin
  inherited CreateEx;
  FHandle := AHandle;
end;

function THandleStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FileRead(FHandle, Buffer, Count);
  if Result = -1 then
    Result := 0;
end;

function THandleStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FileWrite(FHandle, Buffer, Count);
  if Result = -1 then
    Result := 0;
end;

function THandleStream.Seek(const Offset: Integer; Origin: TSeekOrigin):
  Integer;
begin
  Result := FileSeek(FHandle, Offset, Ord(Origin));
end;

procedure THandleStream.SetSize(const NewSize: Integer);
begin
  Seek(NewSize, soBeginning);
end;

function THandleStream.Handle: HFile;
begin
  Result := FHandle;
end;

{ TFileStream }

constructor TFileStream.CreateEx(const FileName: string; Mode: Word);
const
  SFCreateErrorEx = 'Cannot create file "';
  SFOpenErrorEx = 'Cannot open file "';
begin
  FFileName := FileName;
  if Mode = fmCreate then
  begin
    inherited CreateEx(FileCreate(FileName));
    if FHandle < 0 then
    begin
      RaiseError(Self, SFCreateErrorEx + FileName + '". ' +
        SysErrorMessage(GetLastError));
    end;
  end
  else
  begin
    inherited CreateEx(FileOpen(FileName, Mode));
    if FHandle < 0 then
    begin
      RaiseError(Self, SFOpenErrorEx + FileName + '". ' +
        SysErrorMessage(GetLastError));
    end;
  end;
end;

destructor TFileStream.Destroy;
begin
  inherited Destroy;
end;

function TFileStream.FileName: PChar;
begin
  Result := PChar(FFileName);
end;

procedure TFileStream.UnLoad;
begin
  if FHandle >= 0 then
    FileClose(FHandle);
  inherited;
end;

{ TCustomMemoryStream }

procedure TCustomMemoryStream.SetPointer(Ptr: Pointer; Size: Longint);
begin
  FMemory := Ptr;
  FSize := Size;
end;

function TCustomMemoryStream.Read(var Buffer; Count: Longint): Longint;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Result := FSize - FPosition;
    if Result > 0 then
    begin
      if Result > Count then
        Result := Count;
      Move(Pointer(Longint(FMemory) + FPosition)^, Buffer, Result);
      Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
end;

function TCustomMemoryStream.Seek(const Offset: Integer; Origin: TSeekOrigin):
  Integer;
begin
  case Origin of
    soBeginning: FPosition := Offset;
    soCurrent: Inc(FPosition, Offset);
    soEnd: FPosition := FSize + Offset;
  end;
  Result := FPosition;
end;

procedure TCustomMemoryStream.SaveToStream(Stream: IStream);
begin
  if FSize <> 0 then
    Stream.WriteBuffer(FMemory^, FSize);
end;

procedure TCustomMemoryStream.SaveToFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.CreateEx(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

function TCustomMemoryStream.Memory: Pointer;
begin
  Result := FMemory;
end;

{ TMemoryStream }

const
  MemoryDelta = $2000; { Must be a power of 2 }

constructor TMemoryStream.CreateEx(Memory: Pointer; Size: Integer);
begin
  inherited Create;
  FMemory := Memory;
  FSize := Size;
  FNone := True;
end;

constructor TMemoryStream.CreateEx;
begin
  inherited;
  FNone := False;
end;

destructor TMemoryStream.Destroy;
begin
  if not FNone then
    Clear;
  inherited Destroy;
end;

procedure TMemoryStream.Clear;
begin
  SetCapacity(0);
  FSize := 0;
  FPosition := 0;
end;

procedure TMemoryStream.LoadFromStream(Stream: IStream);
var
  Count: Longint;
begin
  Stream.Position := 0;
  Count := Stream.Size;
  SetSize(Count);
  if Count <> 0 then
    Stream.ReadBuffer(FMemory^, Count);
end;

procedure TMemoryStream.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.CreateEx(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TMemoryStream.SetCapacity(NewCapacity: Longint);
begin
  SetPointer(Realloc(NewCapacity), FSize);
  FCapacity := NewCapacity;
end;

procedure TMemoryStream.SetSize(const NewSize: Integer);
var
  OldPosition: Longint;
begin
  OldPosition := FPosition;
  SetCapacity(NewSize);
  FSize := NewSize;
  if OldPosition > NewSize then
    Seek(0, soEnd);
end;

function TMemoryStream.Realloc(var NewCapacity: Longint): Pointer;
const
  SMemoryStreamError = 'Out of memory while expanding memory stream';
begin
  if (NewCapacity > 0) and (NewCapacity <> FSize) then
    NewCapacity := (NewCapacity + (MemoryDelta - 1)) and not (MemoryDelta - 1);
  Result := Memory;
  if NewCapacity <> FCapacity then
  begin
    if NewCapacity = 0 then
    begin
      GlobalFreePtr(Memory);
      Result := nil;
    end
    else
    begin
      if Capacity = 0 then
        Result := GlobalAllocPtr(HeapAllocFlags, NewCapacity)
      else
        Result := GlobalReallocPtr(Memory, NewCapacity, HeapAllocFlags);
      if Result = nil then
      begin
        RaiseError(Self, SMemoryStreamError);
        Exit;
      end;
    end;
  end;
end;

function TMemoryStream.Write(const Buffer; Count: Longint): Longint;
var
  Pos: Longint;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Pos := FPosition + Count;
    if Pos > 0 then
    begin
      if Pos > FSize then
      begin
        if Pos > FCapacity then
          SetCapacity(Pos);
        FSize := Pos;
      end;
      System.Move(Buffer, Pointer(Longint(FMemory) + FPosition)^, Count);
      FPosition := Pos;
      Result := Count;
      Exit;
    end;
  end;
  Result := 0;
end;

//{ TStringStream }

{constructor TStringStream.Create(const AString: string);
begin
  inherited Create;
  FDataString := AString;
end;

function TStringStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := Length(FDataString) - FPosition;
  if Result > Count then
    Result := Count;
  Move(PChar(@FDataString[FPosition + 1])^, Buffer, Result);
  Inc(FPosition, Result);
end;

function TStringStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := Count;
  SetLength(FDataString, (FPosition + Result));
  Move(Buffer, PChar(@FDataString[FPosition + 1])^, Result);
  Inc(FPosition, Result);
end;

function TStringStream.Seek(const Offset: Integer; Origin: TSeekOrigin):
  Integer;
begin
  case Origin of
    soBeginning: FPosition := Offset;
    soCurrent: FPosition := FPosition + Offset;
    soEnd: FPosition := Length(FDataString) - Offset;
  end;
  if FPosition > Length(FDataString) then
    FPosition := Length(FDataString)
  else if FPosition < 0 then
    FPosition := 0;
  Result := FPosition;
end;

function TStringStream.ReadString(Count: Longint): PChar;
var
  Len: Integer;
begin
  Len := Length(FDataString) - FPosition;
  if Len > Count then
    Len := Count;
  Result := PChar(@FDataString[FPosition + 1]);
  Inc(FPosition, Len);
end;

procedure TStringStream.WriteString(const AString: PChar);
begin
  Write(PChar(AString)^, Length(AString));
end;

procedure TStringStream.SetSize(const NewSize: Integer);
begin
  SetLength(FDataString, NewSize);
  if FPosition > NewSize then
    FPosition := NewSize;
end;}

{ TResourceStream }

constructor TResourceStream.Create(Instance: THandle; const ResName: string;
  ResType: PChar);
begin
  inherited Create;
  Initialize(Instance, PChar(ResName), ResType);
end;

constructor TResourceStream.CreateFromID(Instance: THandle; ResID: Integer;
  ResType: PChar);
begin
  inherited Create;
  Initialize(Instance, PChar(ResID), ResType);
end;

procedure TResourceStream.Initialize(Instance: THandle; Name, ResType: PChar);
  procedure Error;
  begin
    RaiseError(Self, 'Resource ' + Name + ' not found');
  end;

begin
  HResInfo := FindResource(Instance, Name, ResType);
  if HResInfo = 0 then
    Error;
  HGlobal := LoadResource(Instance, HResInfo);
  if HGlobal = 0 then
    Error;
  SetPointer(LockResource(HGlobal), SizeOfResource(Instance, HResInfo));
end;

destructor TResourceStream.Destroy;
begin
  UnlockResource(HGlobal);
  FreeResource(HGlobal);
  inherited Destroy;
end;

function TResourceStream.Write(const Buffer; Count: Longint): Longint;
begin
  RaiseError(Self, 'Can''t write to a read-only resource stream');
end;

{ TToolObject }

constructor TToolObject.CreateEx;
begin
  inherited;
  //  _AddRef;
end;

end.

