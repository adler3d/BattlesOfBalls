unit ASDTexture;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 31.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 6.07.07|>}
interface

uses
  Windows, OpenGL, ASDUtils, ASDInterface, ASDType, ASDClasses;

const
  TEX_MAX = 16;

type
  TTexData = record
    ID: Cardinal;
    Width: Integer;
    Height: Integer;
    Ref: Integer;
    Group: Integer;
    Flag: Boolean;
    MipMap: Boolean;
    Name: string;
  end;

  TTexImage = class(TASDObject, ITexImage)
  private
    FID: Cardinal;
    FWidth: Integer;
    FHeight: Integer;
    FGroup: Integer;
    FMipMap: Boolean;
    FName: string;
  public
    constructor CreateEx; override;
    destructor Destroy; override;
    procedure Enable(Channel: Integer);
    procedure Disable(Channel: Integer);
    procedure RenderCopy(X, Y, W, H, Format: Integer; Level: Integer);
    procedure RenderBegin(Mode: TTexMode);
    procedure RenderEnd;
    procedure Filter(FilterType: Integer);
    procedure UnLoad; override;
  public
    function ID: Cardinal;
    function Width: Integer;
    function Height: Integer;
    function Group: Integer;
    function MipMap: Boolean;
    function Name: string;
  end;

  TTexture = class(TASDObject, ITexture)
  private
    FFrame: DWORD;
    FDepth: DWORD;
    FCurmode: Byte;
    FList: TList;
    FTexCur: array[0..TEX_MAX] of HTexture;
    FDefTex: TTexImage; // Текстура по умолчанию
  public
    constructor CreateEx; override;
    destructor Destroy; override;
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
    procedure Delete(Tex:ITexImage);
    procedure Enable(ID: HTexture; Channel: Integer);
    procedure Disable(Channel: Integer);
    procedure Filter(FilterType: Integer; Group: Integer);
    function RenderInit(TexSize: Integer): Boolean;
    procedure UnLoad; override;
    procedure Clear;
  public
    procedure AddLog(Text: string);
    function Init: Boolean;
    function GetTex(const Name: string): ITexImage;
    function NewTex(const Name: string; Data: Pointer; C, F, W, H, Group:
      Integer; Clamp, MipMap: Boolean): ITexImage;
  end;

implementation

uses
  ASDEng, ASDOpenGL, ASDTGA, ASDBJG;

{ TTexImage }

constructor TTexImage.CreateEx;
begin
  inherited CreateEx;
end;

destructor TTexImage.Destroy;
begin
  inherited Destroy;
end;

procedure TTexImage.Disable(Channel: Integer);
begin
  Texture.Disable(Channel);
end;

procedure TTexImage.Enable(Channel: Integer);
begin
  Texture.Enable(FID, Channel);
end;

procedure TTexImage.Filter(FilterType: Integer);
begin
  Enable(0);
  if FMipMap then
    case FilterType of
      FT_NONE:
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
            GL_NEAREST_MIPMAP_NEAREST);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);
        end;
      FT_BILINEAR:
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
            GL_LINEAR_MIPMAP_NEAREST);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);
        end;
      FT_TRILINEAR:
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
            GL_LINEAR_MIPMAP_LINEAR);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);
        end;
      FT_ANISOTROPY:
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
            GL_LINEAR_MIPMAP_LINEAR);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT,
            GL_max_aniso);
        end;
    end
  else
    case FilterType of
      FT_NONE:
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        end;
      FT_BILINEAR, FT_TRILINEAR, FT_ANISOTROPY:
        // без мипмапов - никакой нормальной фильтрации ;)
        begin
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
          glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        end;
    end;
end;

function TTexImage.Group: Integer;
begin
  Result := FGroup;
end;

function TTexImage.Height: Integer;
begin
  Result := FHeight;
end;

function TTexImage.ID: Cardinal;
begin
  Result := FID;
end;

function TTexImage.MipMap: Boolean;
begin
  Result := FMipMap;
end;

function TTexImage.Name: string;
begin
  Result := FName;
end;

procedure TTexImage.RenderBegin(Mode: TTexMode);
begin
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, Texture.FFrame);
  case Mode of
    TM_COLOR: glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,
        GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, ID, 0);
    TM_DEPTH: glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,
        GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, ID, 0);
  end;
  Texture.FCurmode := Texture.FCurmode or Byte(Mode);

  if glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) <>
    GL_FRAMEBUFFER_COMPLETE_EXT then
  begin
    Texture.FCurmode := 0;
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  end;
end;

procedure TTexImage.RenderCopy(X, Y, W, H, Format, Level: Integer);
begin
  Enable(0);
  glCopyTexImage2D(GL_TEXTURE_2D, Level, Format, X, Y, W, H, 0);
  with Texture do
    if (FTexCur[0] = FDefTex.ID) or (FTexCur[0] = 0) then
      Disable(0)
    else
      Enable(FTexCur[0], 0);
end;

procedure TTexImage.RenderEnd;
begin
  if Texture.FCurmode and Byte(TM_COLOR) > 0 then
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
      GL_TEXTURE_2D, 0, 0);
  if Texture.FCurmode and Byte(TM_DEPTH) > 0 then
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
      GL_TEXTURE_2D, 0, 0);
  if Texture.FCurmode > 0 then
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  Texture.FCurmode := 0;
end;

procedure TTexImage.UnLoad;
begin
  Texture.AddLog('Unload ID: ' + IntToStr(FID) + #9 + FName);
  glDeleteTextures(1, @FID);
  //Texture.Delete(Self);
  inherited;
end;

function TTexImage.Width: Integer;
begin
  Result := FWidth;
end;

{ TTexture }

destructor TTexture.Destroy;
begin
  inherited;
end;

//== Создание текстуры по битовом массиву и другим параметрам

function TTexture.Make(Name: PChar; c, f, W, H: Integer; Data: Pointer; Clamp,
  MipMap: Boolean; Group: Integer): ITexImage;
begin
  Result := GetTex(Name);
  if Result = nil then
  begin
    Result := NewTex(Name, Data, c, f, W, H, group, Clamp, MipMap);
    AddLog('Create ID: ' + IntToStr(Result.ID) + #9 + Name);
  end;
end;

//== Загрузка текстуры из TGA, BMP, JPG, GIF (без анимации) файлов

function TTexture.LoadFromFile(FileName: PChar; Clamp, MipMap: Boolean; Group:
  Integer):
  ITexImage;
var
  W, H, b: Integer;
  Data: Pointer;
  c, f: Integer;
begin
  Result := GetTex(FileName);
  if Result = nil then
  try
    // Если текстура не загружена - грузим
    Result := FDefTex;
    if not LoadDataFromFile(FileName, W, H, b, Data) then
      Exit;

    if b = 24 then // Любые текстуры на выходе преобразуются 24 или 32 битные
    begin
      c := GL_RGB8;
      f := GL_BGR;
    end
    else
    begin
      c := GL_RGBA8;
      f := GL_BGRA;
    end;

    Result := NewTex(FileName, Data, c, f, W, H, group, Clamp, MipMap);
    Free(Data);

    AddLog('Loaded ID: ' + IntToStr(Result.ID) + #9 + Result.Name);
  except
    AddLog('Error Loading "' + Result.Name + '"');
    Result := nil;
  end;
end;

//== Загрузка текстуры из памяти (потока)

function TTexture.LoadFromMem(Name: PChar; Mem: Pointer; Size: Integer; Clamp,
  MipMap:
  Boolean; Group: Integer): ITexImage;
var
  W, H, b: Integer;
  Data: Pointer;
  c, f: Integer;
begin
  Result := GetTex(Name);
  if Result = nil then
  try
    // Если текстура не загружена - грузим
    Result := FDefTex;
    if not LoadDataFromMem(Name, Mem, Size, W, H, b, Data) then
      Exit;

    if b = 24 then // Любые текстуры на выходе преобразуются 24 или 32 битные
    begin
      c := GL_RGB8;
      f := GL_BGR;
    end
    else
    begin
      c := GL_RGBA8;
      f := GL_BGRA;
    end;

    Result := NewTex(Name, Data, c, f, W, H, group, Clamp, MipMap);
    Free(Data);

    AddLog('Loaded ID: ' + IntToStr(Result.ID) + #9 + Name);
  except
    AddLog('Error Loading "' + Name + '"');
    Result := nil;
  end;
end;

// Загрузка данных текстуры

function TTexture.LoadDataFromFile(FileName: PChar; var W, H, BPP: Integer; var
  Data:
  Pointer): Boolean;
begin
  if LowerCase(ExtractFileExt(FileName)) = 'tga' then
    Result := LoadTGA(FileName, W, H, BPP, PByteArray(Data))
  else
    Result := LoadBJG(FileName, W, H, BPP, PByteArray(Data));
  if not Result then
    AddLog('Error Loading "' + FileName + '"');
end;

function TTexture.LoadDataFromMem(Name: PChar; Mem: Pointer; Size: Integer; var
  W, H, BPP:
  Integer; var Data: Pointer): Boolean;
begin
  if LowerCase(ExtractFileExt(Name)) = 'tga' then
    Result := LoadTGAmem(Mem, Size, W, H, BPP, PByteArray(Data))
  else
    Result := LoadBJGmem(Mem, Size, W, H, BPP, PByteArray(Data));
  if not Result then
    AddLog('Error Loading "' + Name + '"');
end;

procedure TTexture.Free(var Data: Pointer);
begin
  try
    if Data <> nil then
      FreeMem(Data);
    Data := nil;
  except
    AddLog('error: free data');
  end;
end;

//== Удаление текстуры (если она никем не занята)

procedure TTexture.Enable(ID: HTexture; Channel: Integer);
begin
  if not (Channel in [0..TEX_MAX]) then
    Exit;
  glActiveTextureARB(GL_TEXTURE0_ARB + Channel);
  glEnable(GL_TEXTURE_2D);

  if Texture.FTexCur[Channel] <> ID then
  begin
    glBindTexture(GL_TEXTURE_2D, ID);
    Texture.FTexCur[Channel] := ID;
  end;
end;

procedure TTexture.Disable(Channel: Integer);
begin
  if not (Channel in [0..TEX_MAX]) then
    Exit;
  glActiveTextureARB(GL_TEXTURE0_ARB + Channel);
  glBindTexture(GL_TEXTURE_2D, FDefTex.FID);
  FTexCur[Channel] := FDefTex.FID;
  glDisable(GL_TEXTURE_2D);
end;

procedure TTexture.Filter(FilterType: Integer; Group: Integer);
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
    if (Group and TTexImage(FList[i]).FGroup > 0) or (Group = -1) then
      TTexImage(FList[I]).Filter(FilterType);
  if (FTexCur[0] = FDefTex.FID) or (FTexCur[0] = 0) then
    Disable(0)
  else
    Enable(FTexCur[0], 0);
end;

function TTexture.RenderInit(TexSize: Integer): Boolean;
begin
  // инициализация Frame Buffer
  Result := False;
  if GL_EXT_framebuffer_object then
    if TexSize = 0 then
    begin
      if FFrame <> 0 then
        glDeleteRenderbuffersEXT(1, @FFrame);
      if FDepth <> 0 then
        glDeleteRenderbuffersEXT(1, @FDepth);
      FFrame := 0;
      FDepth := 0;
    end
    else
    begin
      RenderInit(0);
      FCurmode := 0;
      glGenFramebuffersEXT(1, @FFrame);
      glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FFrame);
      // depth
      glGenRenderbuffersEXT(1, @FDepth);
      glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, FDepth);
      glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24_ARB,
        TexSize, TexSize);
      glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
        GL_RENDERBUFFER_EXT, FDepth);
      glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
      Result := True;
    end;
end;

procedure TTexture.AddLog(Text: string);
begin
  Log.Print(Self,PChar(Text));
end;

function TTexture.Init: Boolean;
const
  Size = 32;
var
  pix: array[0..Size - 1, 0..Size - 1] of Byte;
  i: Integer;
begin
  Result := False;
  if not GL_ARB_multitexture then
  begin
    AddLog('Fatal Error "GL_ARB_multitexture"');
    Exit;
  end;

  //== Создаёт Default текстуру
  ZeroMemory(@pix, Size * Size);
  for i := 0 to Size - 1 do
  begin
    pix[i, 0] := 255;
    pix[i, Size - 1] := 255;
    pix[0, i] := 255;
    pix[Size - 1, i] := 255;
    pix[i, i] := 255;
    pix[i, Size - 1 - i] := 255;
  end;

  FDefTex := TTexImage.CreateEx;
  with FDefTex do
  begin
    FWidth := Size;
    FHeight := Size;
    FGroup := 0;
    FMipMap := False;
    FName := 'DefTex';
  end;
  glGenTextures(1, @FDefTex.FID);
  glBindTexture(GL_TEXTURE_2D, FDefTex.FID);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  glTexImage2D(GL_TEXTURE_2D, 0, 1, Size, Size, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,
    @pix);
  Result := True;
end;

function TTexture.GetTex(const Name: string): ITexImage;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FList.Count - 1 do
    if Name = TTexImage(FList[I]).FName then
    begin
      Result := TTexImage(FList[I]);
      Exit;
    end;
end;

function TTexture.NewTex(const Name: string; Data: Pointer; c, f, W, H, Group:
  Integer; Clamp, MipMap: Boolean): ITexImage;
var
  Last: TTexImage;
begin
  Last := TTexImage.CreateEx;
  Last.FName := Name;
  Last.FMipMap := MipMap;
  Last.FGroup := Group;
  FList.Add(Last);
  with Last do
  begin
    FWidth := W;
    FHeight := H;
    FMipMap := MipMap;
    Result := ITexImage(Last);
    glGenTextures(1, @FID);
    glBindTexture(GL_TEXTURE_2D, ID);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

    if Clamp then
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    end
    else
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    end;

    if MipMap then
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_LINEAR_MIPMAP_LINEAR)
    else
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    if MipMap then
      gluBuild2DMipmaps(GL_TEXTURE_2D, c, W, H, f, GL_UNSIGNED_BYTE, Data)
    else
      glTexImage2D(GL_TEXTURE_2D, 0, C, W, H, 0, f, GL_UNSIGNED_BYTE, Data);
  end;
end;

constructor TTexture.CreateEx;
begin
  inherited CreateEx;
  FList := TQuickList.CreateEx;
end;

procedure TTexture.Clear;
var
  I: Integer;
  Tex: TTexImage;
begin
  for I := FList.Count - 1 downto 0 do
  begin
    Tex := TTexImage(FList[I]);
    Tex.UnLoad;
    FList.Delete(I);
  end;
end;

procedure TTexture.UnLoad;
begin
  // Удаление всех текстур
  FDefTex.UnLoad;
  Clear;
  FList.UnLoad;
  RenderInit(0);
  inherited;
end;

procedure TTexture.Delete(Tex: ITexImage);
var
  I:Integer;
begin
  I:=FList.IndexOf(Pointer(Tex));
  if I<>-1 then
  begin
    FList.Delete(I);
  end;
end;

end.

