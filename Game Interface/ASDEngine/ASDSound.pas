unit ASDSound;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 29.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 29.05.07|>}
interface

uses
  Windows, ASDInterface, ASDType, ASDUtils, MMSystem, ASDClasses;

const
  SND_MAX_CHANNELS = 64; // Maximum count of channels
  SND_MAX_TIME = 3000; // Maximum life time after end of channel playing (ms)

type
  IDirectSoundBuffer = interface;
  IDirectSound = interface;

  TDSBufferDesc = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: Pointer;
    guid3DAlgorithm: TGUID;
  end;

  PIDirectSound = ^IDirectSound;

  IDirectSound = interface(IUnknown)
    ['{279AFA83-4981-11CE-A521-0020AF0BE560}']
    function CreateSoundBuffer(const lpDSBufferDesc: TDSBufferDesc;
      out lpIDirectSoundBuffer: IDirectSoundBuffer;
      pUnkOuter: IUnknown): HResult; stdcall;
    function GetCaps(lpDSCaps: Pointer): HResult; stdcall;
    function DuplicateSoundBuffer(lpDsbOriginal: IDirectSoundBuffer;
      out lpDsbDuplicate: IDirectSoundBuffer): HResult; stdcall;
    function SetCooperativeLevel(hwnd: HWND; dwLevel: DWORD): HResult; stdcall;
    function Compact: HResult; stdcall;
    function GetSpeakerConfig(var lpdwSpeakerConfig: DWORD): HResult; stdcall;
    function SetSpeakerConfig(dwSpeakerConfig: DWORD): HResult; stdcall;
    function Initialize(lpGuid: PGUID): HResult; stdcall;
  end;

  IDirectSoundBuffer = interface(IUnknown)
    ['{279AFA85-4981-11CE-A521-0020AF0BE560}']
    function GetCaps(lpDSCaps: Pointer): HResult; stdcall;
    function GetCurrentPosition
      (lpdwPlayPosition, lpdwReadPosition: PDWORD): HResult; stdcall;
    function GetFormat(lpwfxFormat: Pointer; dwSizeAllocated: DWORD;
      lpdwSizeWritten: PDWORD): HResult; stdcall;
    function GetVolume(var lplVolume: integer): HResult; stdcall;
    function GetPan(var lplPan: integer): HResult; stdcall;
    function GetFrequency(var lpdwFrequency: DWORD): HResult; stdcall;
    function GetStatus(var lpdwStatus: DWORD): HResult; stdcall;
    function Initialize(lpDirectSound: IDirectSound;
      const lpcDSBufferDesc: TDSBufferDesc): HResult; stdcall;
    function Lock(dwWriteCursor, dwWriteBytes: DWORD;
      var lplpvAudioPtr1: Pointer; var lpdwAudioBytes1: DWORD;
      var lplpvAudioPtr2: Pointer; var lpdwAudioBytes2: DWORD;
      dwFlags: DWORD): HResult; stdcall;
    function Play(dwReserved1, dwReserved2, dwFlags: DWORD): HResult; stdcall;
    function SetCurrentPosition(dwPosition: DWORD): HResult; stdcall;
    function SetFormat(lpcfxFormat: Pointer): HResult; stdcall;
    function SetVolume(lVolume: integer): HResult; stdcall;
    function SetPan(lPan: integer): HResult; stdcall;
    function SetFrequency(dwFrequency: DWORD): HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(lpvAudioPtr1: Pointer; dwAudioBytes1: DWORD;
      lpvAudioPtr2: Pointer; dwAudioBytes2: DWORD): HResult; stdcall;
    function Restore: HResult; stdcall;
  end;

  TSChannel = object
    Buffer: IDirectSoundBuffer; // Direct Sound buffer
    SID: Integer; // ID исходного сэмпла
    Sample: Boolean; // True для сэмпла-исходника
    Playing: Boolean; // Проигрывается в данный момент
    Timer: DWORD; // Счётчик времени ожидания для канала (при значении = SND_MAX_TIME - умирает)
    Group: Integer; // Номер группы
    Flag: Boolean; // Флаг обновления
    Ref: Integer; // Счётчик ссылок
    Pos: TVector3D; // Позиция канала
    FileName: string; // Имя файла сэмпла-исходника
  end;

  TSound = class(TASDObject, ISound)
    function Load(FileName: PChar; Group: Integer): HSound; overload;
    function Load(Name: PChar; Mem: Pointer; Size: Integer; Group: Integer): HSound; overload;
    function Free(ID: HSound): Boolean;
    function Play(ID: HSound; X, Y, Z: Single; Loop: Boolean): HChannel;
    procedure Stop(ID: HChannel);
    procedure Update_Begin(Group: Integer);
    procedure Update_End(Group: Integer);
    procedure Volume(Value: Integer);
    procedure Freq(Value: Integer);
    procedure Channel_Pos(ID: HChannel; X, Y, Z: Single);
    procedure Pos(X, Y, Z: Single);
    procedure Dir(dX, dY, dZ, uX, uY, uZ: Single);
    procedure Factor_Pan(Value: Single);
    procedure Factor_Rolloff(Value: Single);
    procedure PlayFile(FileName: PChar; Loop: Boolean);
    procedure StopFile;
  public
    snd_ready: Boolean; // К бою готов? ;)
    snd_count_playing: Integer; // кол-во проигрываемых каналов
    snd_count_active: Integer; // кол-во активных каналов (buffer <> nil)
    snd_count_samples: Integer; // клд-во загруженных сэмплов
    snd_volume: Integer; // Громкость по умолчанию (максимум)
    snd_freq: Integer; // Целевая частота
    snd_off: Boolean; // Вкл/Выкл звук
  // pan control
    snd_swap: Boolean; // Меняет левый и правый каналы местами
    snd_factor_pan: Single;
    snd_factor_rolloff: Single;
    snd_pos: TVector3D;
    snd_dir: record
      dX, dY, dZ: Single;
      uX, uY, uZ: Single;
    end;
    snd_plane: record
      ASDEng, B, C: Single;
    end;
  // MMS
    music_ID: WORD;
    music_Loop: Boolean;
    music_Param: TMCI_PLAY_PARMS;
    procedure AddLog(Text: string);
    procedure Init;
    procedure Channel_Volume(ID: HChannel; Value: Integer);
    function GetFreeID: Integer;
    procedure Calc(CID: Integer);
    procedure Update;
    procedure ReplayFile;
    function Load(Stream: TStream; Name: PChar; Group: Integer): HSound; overload;
    constructor CreateEx; override;
  end;

implementation
uses
  ASDWindow, ASDEng;
var
  DSoundDLL: HMODULE;
  DirectSoundCreate: function(lpGuid: PGUID; out ppDS: IDirectSound; pUnkOuter: IUnknown): HResult; stdcall;

threadvar
// DSound interfaces
  DSMain: IDirectSound;
  Channels: array[0..SND_MAX_CHANNELS - 1] of TSChannel;

// DirectSound v5.0 interfaces & constants
const
  DS_OK = $00000000;
  DSSCL_PRIORITY = $00000002;
  DSBPLAY_LOOPING = $00000001;
  DSBPAN_LEFT = -10000;
  DSBPAN_RIGHT = 10000;
  DSBVOLUME_MIN = -10000;
  DSBVOLUME_MAX = 0;
  DSBSTATUS_PLAYING = $00000001;
  DSBSTATUS_BUFFERLOST = $00000002;
  DSBLOCK_ENTIREBUFFER = $00000002;

  DSBCAPS_STATIC = $00000002;
  DSBCAPS_LOCSOFTWARE = $00000008;
  DSBCAPS_CTRLFREQUENCY = $00000020;
  DSBCAPS_CTRLPAN = $00000040;
  DSBCAPS_CTRLVOLUME = $00000080;
  DSBCAPS_GLOBALFOCUS = $00008000;


function TSound.Load(FileName: PChar; Group: Integer): HSound;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.CreateEx(FileName,fmOpenRead);
  Result := Load(Stream, FileName, Group);
  Stream.Free;
end;

function TSound.Load(Name: PChar; Mem: Pointer; Size: Integer; Group: Integer): HSound;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.CreateEx(Mem, Size);
  Result := Load(Stream, Name, Group);
  Stream.Free;
end;

function TSound.Free(ID: HSound): Boolean;
begin
  Result := False;
  if not snd_ready then
    Exit;

  if (ID > -1) and (ID < SND_MAX_CHANNELS) and
    (Channels[ID].Buffer <> nil) then
  begin
    if Channels[ID].Ref = 1 then
      Channels[ID].Buffer := nil
    else
      dec(Channels[ID].Ref);
    Result := True;
  end;
end;

function TSound.Play(ID: HSound; X, Y, Z: Single; Loop: Boolean): HChannel;
var
  i: Integer;
  NID: Integer;
begin
  Result := -1;
  if (not snd_ready) or snd_off or
    (ID < 0) or (ID >= SND_MAX_CHANNELS) or
    (Channels[ID].Buffer = nil) or
    (not Channels[ID].Sample) then
    Exit;

  NID := -1;
// поиск остановленного канала с ID = SID...
  for i := 0 to SND_MAX_CHANNELS - 1 do
    if (Channels[i].SID = ID) and
      (not Channels[i].Playing) and
      (Channels[i].Buffer <> nil) then
    begin
    // и его проигрывание
      NID := i;
      break;
    end;

// если не нашли - дублируем буфер в новый "полностью свободный" канал
  if NID = -1 then
  begin
    NID := GetFreeID;
  // если все каналы заняты - не судьба ;)
    if NID = -1 then
      Exit;
  // иначе дублируем сэмпл-исходник как и планировалось (NID)
    Channels[NID].SID := ID;
    Channels[NID].Flag := False;
    Channels[NID].Sample := False;
    Channels[NID].Buffer := nil;
    DSMain.DuplicateSoundBuffer(Channels[ID].Buffer,
      Channels[NID].Buffer);
  end;

  if not Channels[NID].Sample then
    Channels[NID].Ref := 1;
  Channels[NID].Pos:=MakeVector3D(X, Y, Z);
  with Channels[NID] do
  begin
    Calc(NID);
    Buffer.SetFrequency(snd_freq);
    Playing := Buffer.Play(0, 0, DSBPLAY_LOOPING and Byte(Loop)) = DS_OK;
  end;
  Result := NID;
end;

procedure TSound.Stop(ID: HChannel);
var
  i: Integer;
begin
  if (not snd_ready) or
    (ID < -1) or (ID >= SND_MAX_CHANNELS) then
    Exit;
  if ID > -1 then
  begin
    with Channels[ID] do
      if Playing and (Buffer <> nil) then
        Buffer.Stop;
  end else // если ID = -1 - останавливаем все каналы
    for i := 0 to SND_MAX_CHANNELS - 1 do
      with Channels[i] do
        if Playing and (Buffer <> nil) then
          Buffer.Stop;
end;

procedure TSound.Update_Begin(Group: Integer);
var
  i: Integer;
begin
//== Group = -1 - обновление всех каналов/сэмплов
  for i := 0 to SND_MAX_CHANNELS - 1 do
    if (Group and Channels[i].Group > 0) or (group = -1) then
      Channels[i].Flag := True;
end;

procedure TSound.Update_End(Group: Integer);
var
  i: Integer;
begin
  for i := 0 to SND_MAX_CHANNELS - 1 do
    if ((Group and Channels[i].Group > 0) or (Group = -1)) and Channels[i].Flag then
      Free(i);
end;

procedure TSound.Volume(Value: Integer);
var
  i: Integer;
begin
  if not snd_ready then
    Exit;
  snd_volume := Value;
  if snd_volume > 100 then snd_volume := 100;
  if snd_volume < 0 then snd_volume := 0;
  for i := 0 to SND_MAX_CHANNELS - 1 do
    with Channels[i] do
      if Playing and (Buffer <> nil) then
        Channel_Volume(i, Value);
end;

procedure TSound.Freq(Value: Integer);
var
  i: Integer;
begin
  if not snd_ready then
    Exit;
  snd_freq := Value;
  for i := 0 to SND_MAX_CHANNELS - 1 do
    with Channels[i] do
      if Playing and (Buffer <> nil) then
        Buffer.SetFrequency(snd_freq);
end;

procedure TSound.Channel_Pos(ID: HChannel; X, Y, Z: Single);
begin
  if (not snd_ready) or
    (ID < 0) or (ID >= SND_MAX_CHANNELS) or
    (Channels[ID].Buffer = nil) then
    Exit;
  Channels[ID].Pos:=MakeVector3D(X, Y, Z);
  Calc(ID);
end;

procedure TSound.Pos(X, Y, Z: Single);
begin
  if not snd_ready then
    Exit;
  snd_pos:=MakeVector3D(X, Y, Z);
end;

procedure TSound.Dir(dX, dY, dZ, uX, uY, uZ: Single);
begin
  snd_dir.dX := dX;
  snd_dir.dY := dY;
  snd_dir.dZ := dZ;
  snd_dir.uX := uX;
  snd_dir.uY := uY;
  snd_dir.uZ := uZ;
end;

procedure TSound.Factor_Pan(Value: Single);
begin
  snd_factor_pan := Value;
end;

procedure TSound.Factor_Rolloff(Value: Single);
begin
  snd_factor_rolloff := Value;
end;

procedure TSound.PlayFile(FileName: PChar; Loop: Boolean);
var
  mciOpen: TMCI_OPEN_PARMS;
begin
  music_Loop := Loop;
  if music_ID <> 0 then
    StopFile;

  with mciOpen do
  begin
    dwCallBack := 0;
    lpstrDeviceType := nil;
    lpstrElementName := FileName;
    lpstrAlias := nil;
  end;

  if mciSendCommand(0, MCI_OPEN, MCI_OPEN_ELEMENT, Integer(@mciOpen)) = 0 then
  begin
    music_ID := mciOpen.wDeviceId;
    music_Param.dwCallBack := Window.Handle;
    music_Param.dwFrom := 0;
    mciSendCommand(music_ID, MCI_PLAY, MCI_NOTIFY or MCI_FROM, Integer(@music_Param));
  end;
end;

procedure TSound.StopFile;
begin
  mciSendCommand(music_ID, MCI_CLOSE, 0, 0);
  music_ID := 0;
end;

procedure TSound.AddLog(Text: string);
begin
  Log.Print(Self,PChar(Text));
end;

procedure TSound.Init;
begin
  if DSoundDLL = 0 then
    Exit;

  if DirectSoundCreate(nil, DSMain, nil) <> DS_OK then
  begin
    FreeLibrary(DSoundDLL);
    DSoundDLL := 0;
    AddLog('Fatal Error "DirectSoundCreate"');
    Exit;
  end;

  ZeroMemory(@Channels, SizeOf(Channels));

  snd_count_playing := 0;
  snd_count_active := 0;
  snd_count_samples := 0;
  snd_volume := 100;
  snd_freq := 22050;
  snd_off := False;
// pan control
  snd_swap := False;
  snd_factor_pan := 0.1;
  snd_factor_rolloff := 0.005;

  Pos(0, 0, 0);
  Dir(0, 0, -1, 0, 1, 0);

  if DSMain.SetCooperativeLevel(Window.Handle, DSSCL_PRIORITY) <> DS_OK then
    AddLog('Can''t SetCooperativeLevel');
  snd_ready := True;

  AddLog('DirectSound Initialized');
end;

function TSound.GetFreeID: Integer;
var
  i: Integer;
begin
//== поиск свободного канала ("полностью свободные" (те что без сэмпла вовсе) имеют высший приоритет)
  Result := -1;
  for i := 0 to SND_MAX_CHANNELS - 1 do
    with Channels[i] do
      if (not Sample) and
        ((not Playing) or (Buffer = nil)) then
      begin
        Result := i;
        if Buffer = nil then
          break;
      end;
end;

procedure TSound.Calc(CID: Integer);
var
  i: Integer;
  dist: Single;
  ang: Single;
begin
//== Recalc channel volume and pan
  with Channels[CID], Pos do
  begin
  // находим косинус угла между вектором до источника и нормалью плоскости
    dist := sqrt(sqr(snd_pos.X - X) + sqr(snd_pos.Y - Y) + sqr(snd_pos.Z - Z));
    if dist = 0 then
      ang := 0
    else
      with snd_plane do
        ang := (ASDEng * (snd_pos.X - X) + B * (snd_pos.Y - Y) + C * (snd_pos.Z - Z)) / dist;
    i := trunc(DSBPAN_LEFT * ang * snd_factor_pan);
    if i < DSBPAN_LEFT then i := DSBPAN_LEFT;
    if i > DSBPAN_RIGHT then i := DSBPAN_RIGHT;
    if snd_swap then
      i := -i;
    Buffer.SetPan(i);
    i := trunc((1 - dist * snd_factor_rolloff) * 100);
    if i < 0 then
      i := 0;
    Channel_Volume(CID, i);
  end;
end;

procedure TSound.Channel_Volume(ID: HChannel; Value: Integer);
begin
//== Установка громкости звука для канала
  with Channels[ID] do
    Buffer.SetVolume(trunc(sqrt(Value * snd_volume * 0.0001) * (DSBVOLUME_MAX - DSBVOLUME_MIN) + DSBVOLUME_MIN));
end;

procedure TSound.Update;
var
  i: Integer;
  Status: DWORD;
  CurTime: DWORD;
begin
  if not snd_ready then
    Exit;

// Считаем плоскость относительно которой будет расчитываться громкость звука
// в левом и правом канале
  with snd_plane, snd_dir do
  begin
  // по векторам Dir и Up находим Left вектор являющийся нормалью к плоскости
    ASDEng := dY * uZ - dZ * uY;
    B := dZ * uX - dX * uZ;
    C := dX * uY - dY * uX;
  // находим расстояние по нормали от позиции слушателя
  // D = -(Ax + By + Cz)
  //  D := -(ASDEng * X + B * Y + C * Z);
  end;

  snd_count_playing := 0;
  snd_count_active := 0;
  snd_count_samples := 0;
  CurTime := GetTickCount;
// Recalc channels status
  for i := 0 to SND_MAX_CHANNELS - 1 do
    with Channels[i] do
      if Buffer <> nil then
      begin
        Buffer.GetStatus(Status);
        if Status and DSBSTATUS_BUFFERLOST <> 0 then
          Buffer.Restore
        else
          if status and DSBSTATUS_PLAYING <> 0 then
          begin
            Calc(i);
            inc(snd_count_playing);
          end else
          begin
            if not Sample then
              if Playing then
                Timer := CurTime
              else
                if CurTime - Timer > SND_MAX_TIME then
                begin
                  Buffer := nil;
                  continue;
                end;
            Playing := False;
          end;
        if Sample then
          inc(snd_count_samples);
        inc(snd_count_active);
      end;
end;

procedure TSound.ReplayFile;
begin
  if (music_ID <> 0) and (music_Loop) then
  begin
    mciSendCommand(music_ID, MCI_SEEK, MCI_SEEK_TO_START, 0);
    music_Param.dwCallback := Window.Handle;
    mciSendCommand(music_ID, MCI_PLAY, MCI_NOTIFY, Integer(@music_Param));
  end;
end;

function TSound.Load(Stream: TStream; Name: PChar; Group: Integer): HSound;
var
  i: Integer;
  NID: Integer;

// Microsoft Wave file format header
  WaveHeader: record
    RIFF: array[0..3] of Char;
    rlen: DWORD;
    WAVE: array[0..3] of Char;
  // PCM fmt
    fmt: array[0..3] of Char;
    flen: DWORD;
    wFormatTag: Word;
    nChannels: Word;
    nSamplesPerSec: DWORD;
    nAvgBytesPerSec: DWORD;
    nBlockAlign: Word;
    wBitsPerSample: Word;
  // data
    DATA: array[0..3] of Char;
    dlen: DWORD;
  end;

  ap1, ap2: Pointer;
  as1, as2: DWORD;
  BufferDesc: TDSBufferDesc;
begin
  Result := -1;
  if not snd_ready then
    Exit;

// Если сэмпл уже загружен...
  for i := 0 to SND_MAX_CHANNELS - 1 do
    if (Channels[i].FileName = Name) and
      (Channels[i].Buffer <> nil) then
    begin
    // используем его
      Result := i;
      inc(Channels[i].Ref);
      Exit;
    end;

  NID := GetFreeID;
  if NID = -1 then
    Exit;

  try
// Загрузка сэмпла из wav файла
    if not Stream.Valid then
    begin
      AddLog('Can''t load "' + Name + '"');
      Exit;
    end;
    Stream.Read(WaveHeader, SizeOf(WaveHeader));

// чтение некоторых свойств wave данных из файла
    with WaveHeader do
    begin
      if (RIFF <> 'RIFF') or (WAVE <> 'WAVE') or
        (wBitsPerSample < 8) then
      begin
        AddLog('Invalid wave format "' + Name + '"');
        Exit;
      end;
      nBlockAlign := wBitsPerSample div 8 * nChannels;
      nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
    end;

// Подготавливаем описание статического буфера
    ZeroMemory(@BufferDesc, SizeOf(BufferDesc));
    with BufferDesc do
    begin
      dwSize := SizeOf(BufferDesc);
      dwFlags := DSBCAPS_LOCSOFTWARE or
        DSBCAPS_STATIC or
        DSBCAPS_GLOBALFOCUS or
        DSBCAPS_CTRLFREQUENCY or
        DSBCAPS_CTRLPAN or
        DSBCAPS_CTRLVOLUME;
      dwBufferBytes := WaveHeader.dlen;
      lpwfxFormat := @WaveHeader.wFormatTag;
    end;

// Создание буфера для канала
    Channels[NID].Buffer := nil;
    if DSMain.CreateSoundBuffer(BufferDesc, Channels[NID].Buffer, nil) <> DS_OK then
    begin
      AddLog('Can''t create sound buffer for "' + Name + '"');
      Exit;
    end;

// Изменяем содержимое буфера
    ap2 := nil;
    as2 := 0;
    if Channels[NID].Buffer.Lock(0, 0, ap1, as1, ap2, as2, DSBLOCK_ENTIREBUFFER) <> DS_OK then
    begin
      AddLog('Can''t lock buffer data for "' + Name + '"');
      Exit;
    end;

// Запись данных в буфер
    Stream.Read(ap1^, WaveHeader.dlen);

    if Channels[NID].Buffer.Unlock(ap1, as1, ap2, as2) <> DS_OK then
    begin
      AddLog('Can''t unlock buffer data for "' + Name + '"');
      Exit;
    end;
    Channels[NID].FileName := Name;
    Channels[NID].SID := NID;
    Channels[NID].Ref := 1;
    Channels[NID].Sample := True;
    Channels[NID].Flag := False;
    Channels[NID].Playing := False;
    Channels[NID].Group := Group;
    Result := NID;
    AddLog('Loaded "' + Name + '"');
  except
    AddLog('Error Loading "' + Name + '"');
  end;
end;

constructor TSound.CreateEx;
begin
  inherited CreateEx;
end;

initialization
  DSoundDLL := LoadLibrary('DSound.dll');
  DirectSoundCreate := GetProcAddress(DSoundDLL, 'DirectSoundCreate');
finalization
  FreeLibrary(DSoundDLL);
end.

