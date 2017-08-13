unit ASDOpenGL;
{<|Модуль библиотеки ASDEngine|>}
{<|Дата создания 31.05.07|>}
{<|Автор Adler3D|>}
{<|e-mail : Adler3D@Mail.ru|>}
{<|Дата последнего изменения 31.05.07|>}
interface

uses
  Windows, OpenGL,
  ASDUtils, ASDInterface, ASDType, ASDLog, ASDClasses;

type
  PFontData = ^TFontData;
  TFontData = record
    Font: ITexImage;
    List: Cardinal;
    Size: Cardinal;
    Width: array[0..255] of ShortInt;
  end;

  GLHandleARB = Integer;

  TOpenGL = class(TASDObject, IOpenGL)
  private
    FNPS: TCalcNPS;
  public
    constructor CreateEx; override;
    destructor Destroy; override;
    procedure UnLoad; override;
  public
    function FPS: Integer;
    procedure VSync(Active: Boolean); overload;
    function VSync: Boolean; overload;
    procedure Clear(Color, Depth, Stencil: Boolean);
    procedure Swap;
    procedure AntiAliasing(Samples: Integer); overload;
    function AntiAliasing: Integer; overload;
    procedure Set2D(x, y, w, h: Single);
    procedure Set3D(FOV, zNear, zFar: Single);
    procedure LightDef(ID: Integer);
    procedure LightPos(ID: Integer; X, Y, Z: Single);
    procedure LightColor(ID: Integer; R, G, B: Single);
    function FontCreate(Name: PChar; Size: Integer): TFont;
    procedure FontFree(Font: TFont);
    procedure TextOut(Font: TFont; X, Y: Real; Text: PChar);
    function TextLen(Font: TFont; Text: PChar): Integer;
    function FontHeigth(Font: TFont): Integer;
    procedure Blend(BType: TBlendType);
    function ScreenShot(FileName: PChar): Boolean;
  public
    DC: HDC; // Device Context
    RC: HGLRC; // OpenGL Rendering Context
    fnt_debug: Integer;
    // fps - frames per second
    AASamples: Integer;
    AAFormat: Integer;
    g_vsync: Boolean;
    Fonts: array of PFontData;
    extension: string; // Строка содержит в себе все доступные OpenGL расширения
    procedure AddLog(Text: string);
    procedure GetPixelFormat;
    function Init: Boolean;
    procedure ReadExtensions;
  end;

  // Процедурки и константы отсутствующие в стандартном OpenGL.pas
const
  // Textures
  GL_MAX_TEXTURE_UNITS_ARB = $84E2;
  GL_MAX_TEXTURE_SIZE = $0D33;
  GL_CLAMP_TO_EDGE = $812F;
  GL_RGB8 = $8051;
  GL_RGBA8 = $8058;
  GL_BGR = $80E0;
  GL_BGRA = $80E1;
  GL_TEXTURE0_ARB = $84C0;
  GL_TEXTURE1_ARB = $84C1;
  GL_TEXTURE_MAX_ANISOTROPY_EXT = $84FE;
  GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT = $84FF;

  // AA
  WGL_SAMPLE_BUFFERS_ARB = $2041; // Symbolickй konstanty pro multisampling
  WGL_SAMPLES_ARB = $2042;
  WGL_DRAW_TO_WINDOW_ARB = $2001;
  WGL_SUPPORT_OPENGL_ARB = $2010;
  WGL_DOUBLE_BUFFER_ARB = $2011;

  // FBO
  GL_FRAMEBUFFER_EXT = $8D40;
  GL_RENDERBUFFER_EXT = $8D41;
  GL_DEPTH_COMPONENT24_ARB = $81A6;
  GL_COLOR_ATTACHMENT0_EXT = $8CE0;
  GL_DEPTH_ATTACHMENT_EXT = $8D00;
  GL_FRAMEBUFFER_BINDING_EXT = $8CA6;
  GL_FRAMEBUFFER_COMPLETE_EXT = $8CD5;
  // Shaders
  GL_VERTEX_SHADER_ARB = $8B31;
  GL_FRAGMENT_SHADER_ARB = $8B30;
  GL_OBJECT_COMPILE_STATUS_ARB = $8B81;
  GL_OBJECT_LINK_STATUS_ARB = $8B82;
  // VBO
  GL_ARRAY_BUFFER_ARB = $8892;
  GL_ELEMENT_ARRAY_BUFFER_ARB = $8893;
  GL_STATIC_DRAW_ARB = $88E4;
  GL_NORMAL_ARRAY = $8075;
  GL_COLOR_ARRAY = $8076;
  GL_VERTEX_ARRAY = $8074;
  GL_TEXTURE_COORD_ARRAY = $8078;

procedure glGenTextures(n: GLsizei; textures: PGLuint); stdcall; external
opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external
opengl32;
procedure glDeleteTextures(N: GLsizei; Textures: PGLuint); stdcall; external
opengl32;
function glIsTexture(texture: GLuint): GLboolean; stdcall; external opengl32;
procedure glCopyTexImage2D(target: GLEnum; level: GLint; internalFormat: GLEnum;
  x, y: GLint; width, height: GLsizei; border: GLint); stdcall; external
    opengl32;

var
  // VSync
  WGL_EXT_swap_control: Boolean;
  wglSwapIntervalEXT: function(interval: GLint): Boolean; stdcall;
  wglGetSwapIntervalEXT: function: GLint; stdcall;

  // MultiTexture
  GL_ARB_multitexture: Boolean;
  glActiveTextureARB: procedure(texture: GLenum); stdcall;
  glClientActiveTextureARB: procedure(texture: Cardinal); stdcall;

  // FrameBuffer
  GL_EXT_framebuffer_object: Boolean;
  glGenRenderbuffersEXT: procedure(n: GLsizei; renderbuffers: PGLuint); stdcall;
  glDeleteRenderbuffersEXT: procedure(n: GLsizei; const renderbuffers: PGLuint);
  stdcall;
  glBindRenderbufferEXT: procedure(target: GLenum; renderbuffer: GLuint);
  stdcall;
  glRenderbufferStorageEXT: procedure(target: GLenum; internalformat: GLenum;
    width: GLsizei; height: GLsizei); stdcall;
  glGenFramebuffersEXT: procedure(n: GLsizei; framebuffers: PGLuint); stdcall;
  glDeleteFramebuffersEXT: procedure(n: GLsizei; const framebuffers: PGLuint);
  stdcall;
  glBindFramebufferEXT: procedure(target: GLenum; framebuffer: GLuint); stdcall;
  glFramebufferTexture2DEXT: procedure(target: GLenum; attachment: GLenum;
    textarget: GLenum; texture: GLuint; level: GLint); stdcall;
  glFramebufferRenderbufferEXT: procedure(target: GLenum; attachment: GLenum;
    renderbuffertarget: GLenum; renderbuffer: GLuint); stdcall;
  glCheckFramebufferStatusEXT: function(target: GLenum): GLenum; stdcall;

  // Shaders
  GL_ARB_shading_language: Boolean;
  glDeleteObjectARB: procedure(Obj: GLHandleARB); stdcall;
  glCreateProgramObjectARB: function: GLHandleARB; stdcall;
  glCreateShaderObjectARB: function(shaderType: GLEnum): GLHandleARB; stdcall;
  glShaderSourceARB: procedure(shaderObj: GLHandleARB; count: GLSizei; src:
    Pointer; len: Pointer); stdcall;
  glAttachObjectARB: procedure(programObj, shaderObj: GLhandleARB); stdcall;
  glLinkProgramARB: procedure(programObj: GLHandleARB); stdcall;
  glUseProgramObjectARB: procedure(programObj: GLHandleARB); stdcall;
  glCompileShaderARB: function(shaderObj: GLHandleARB): GLboolean; stdcall;
  glGetObjectParameterivARB: procedure(Obj: GLHandleARB; pname: GLEnum; params:
    PGLuint); stdcall;
  glGetAttribLocationARB: function(programObj: GLhandleARB; const char: PChar):
  GLInt; stdcall;
  glGetUniformLocationARB: function(programObj: GLhandleARB; const char: PChar):
  GLInt; stdcall;
  glVertexAttrib1fARB: procedure(index: GLuint; x: GLfloat); stdcall;
  glVertexAttrib2fARB: procedure(index: GLuint; x, y: GLfloat); stdcall;
  glVertexAttrib3fARB: procedure(index: GLuint; x, y, z: GLfloat); stdcall;
  glUniform1fARB: procedure(location: GLint; v0: GLfloat); stdcall;
  glUniform2fARB: procedure(location: GLint; v0, v1: GLfloat); stdcall;
  glUniform3fARB: procedure(location: GLint; v0, v1, v2: GLfloat); stdcall;
  glUniform4fARB: procedure(location: GLint; v0, v1, v2, v3: GLfloat); stdcall;
  glUniform1iARB: procedure(location: GLint; v0: GLint); stdcall;

  // Vertex Buffer Object
  GL_ARB_vertex_buffer_object: Boolean;
  glBindBufferARB: procedure(target: GLenum; buffer: GLenum); stdcall;
  glDeleteBuffersARB: procedure(n: GLsizei; const buffers: PGLuint); stdcall;
  glGenBuffersARB: procedure(n: GLsizei; buffers: PGLuint); stdcall;
  glBufferDataARB: procedure(target: GLenum; size: GLsizei; const data: PGLuint;
    usage: GLenum); stdcall;
  glBufferSubDataARB: procedure(target: GLenum; offset: GLsizei; size: GLsizei;
    const data: PGLuint); stdcall;

procedure glNormalPointer(type_: GLenum; stride: Integer; const P: PGLuint);
stdcall; external opengl32;
procedure glColorPointer(size: Integer; _type: GLenum; stride: Integer; const
  _pointer: PGLuint); stdcall; external opengl32;
procedure glVertexPointer(size: Integer; _type: GLenum; stride: Integer; const
  _pointer: PGLuint); stdcall; external opengl32;
procedure glTexCoordPointer(size: Integer; _type: GLenum; stride: Integer; const
  _pointer: PGLuint); stdcall; external opengl32;

procedure glInterleavedArrays(format: GLenum; stride: GLsizei; const _pointer:
  PGLuint); stdcall; external opengl32;
procedure glEnableClientState(_array: GLenum); stdcall; external opengl32;
procedure glDisableClientState(_array: GLenum); stdcall; external opengl32;
procedure glDrawElements(mode: GLenum; count: GLsizei; _type: GLenum; const
  indices: PGLuint); stdcall; external opengl32;

var
  GL_max_Aniso: Integer;

implementation

uses
  ASDEng;

constructor TOpenGL.CreateEx;
begin
  inherited CreateEx;
  g_vsync := False;
  FNPS := TCalcNPS.CreateEx(1000);
  FNPS.Mode := cmAccum;
end;

destructor TOpenGL.Destroy;
var
  I: Integer;
begin
  for i := 0 to Length(Fonts) - 1 do
    FontFree(i);
  if (DC <> 0) and (RC <> 0) then
  begin
    if RC <> 0 then
      wglDeleteContext(RC);
    if DC <> 0 then
      ReleaseDC(Window.Handle, DC);
  end;
  inherited;
end;

function TOpenGL.FPS: Integer;
begin
  Result := Round(FNPS.NPS);
end;

procedure TOpenGL.VSync(Active: Boolean);
begin
  g_vsync := Active;
end;

function TOpenGL.VSync: Boolean;
begin
  Result := g_vsync;
end;

procedure TOpenGL.Clear(Color, Depth, Stencil: Boolean);
var
  flag: DWORD;
begin
  flag := 0;
  if Color then
    flag := flag or GL_COLOR_BUFFER_BIT;
  if Depth then
    flag := flag or GL_DEPTH_BUFFER_BIT;
  if Stencil then
    flag := flag or GL_STENCIL_BUFFER_BIT;
  glClear(flag);
end;

procedure TOpenGL.Swap;
begin
  if WGL_EXT_swap_control and (wglGetSwapIntervalEXT <> Byte(g_vsync)) then
    wglSwapIntervalEXT(Byte(g_vsync));
  glFlush;
  SwapBuffers(DC);
  FNPS.Next;
end;

procedure TOpenGL.AntiAliasing(Samples: Integer);
begin
  if not Window.Ready then
    AASamples := Samples;
end;

function TOpenGL.AntiAliasing: Integer;
begin
  Result := AASamples
end;

procedure TOpenGL.Set2D(x, y, w, h: Single);
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(x, x + w, y + h, y, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TOpenGL.Set3D(FOV, zNear, zFar: Single);
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(FOV, Window.Width / Window.Height, zNear, zFar);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TOpenGL.LightDef(ID: Integer);
const
  light_position: array[0..3] of single = (1, 1, 1, 0);
  white_light: array[0..3] of single = (1, 1, 1, 1);
begin
  glLightfv(ID, GL_POSITION, @light_position);
  glLightfv(ID, GL_DIFFUSE, @white_light);
  glLightfv(ID, GL_SPECULAR, @white_light);
end;

procedure TOpenGL.LightPos(ID: Integer; X, Y, Z: Single);
var
  p: array[0..3] of Single;
begin
  p[0] := X;
  p[1] := Y;
  p[2] := Z;
  p[3] := 1;
  glLightfv(ID, GL_POSITION, @p);
end;

procedure TOpenGL.LightColor(ID: Integer; R, G, B: Single);
var
  c: array[0..3] of Single;
begin
  c[0] := R;
  c[1] := G;
  c[2] := B;
  c[3] := 1;
  glLightfv(ID, GL_DIFFUSE, @c);
  glLightfv(ID, GL_SPECULAR, @c);
end;

function TOpenGL.FontCreate(Name: PChar; Size: Integer): TFont;
const
  TEX_SIZE = 512;
var
  FNT: HFONT;
  DC: HDC;
  MDC: HDC;
  BMP: HBITMAP;
  BI: BITMAPINFO;
  pix: PByteArray;
  i: Integer;
  cs: TSize;
  s, t: Single;
  Data: PByteArray;
begin
  DC := GetDC(Window.Handle);
  FNT := CreateFont(-MulDiv(Size, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0,
    0, 0, 0, 0, DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
    ANTIALIASED_QUALITY, 0, Name);
  ZeroMemory(@BI, SizeOf(BI));
  with BI.bmiHeader do
  begin
    biSize := SizeOf(BITMAPINFOHEADER);
    biWidth := TEX_SIZE;
    biHeight := TEX_SIZE;
    biPlanes := 1;
    biBitCount := 24;
    biSizeImage := biWidth * biHeight * biBitCount div 8;
  end;

  MDC := CreateCompatibleDC(DC);
  BMP := CreateDIBSection(MDC, BI, DIB_RGB_COLORS, Pointer(pix), 0, 0);
  ZeroMemory(pix, TEX_SIZE * TEX_SIZE * 3);

  SelectObject(MDC, BMP);
  SelectObject(MDC, FNT);
  SetBkMode(MDC, TRANSPARENT);
  SetTextColor(MDC, $FFFFFF);

  for i := 0 to 255 do
    Windows.TextOut(MDC, i mod 16 * (TEX_SIZE div 16), i div 16 * (TEX_SIZE div
      16), @Char(i), 1);

  Result := HIGH(TFont);
  for i := 0 to Length(Fonts) - 1 do
    if Fonts[i] = nil then
    begin
      Result := i;
      break;
    end;
  if Result = HIGH(TFont) then
  begin
    Result := Length(Fonts);
    SetLength(Fonts, Result + 1);
  end;

  New(Fonts[Result]);
  with Fonts[Result]^ do
  begin
    GetMem(Data, TEX_SIZE * TEX_SIZE * 2);
    for i := 0 to TEX_SIZE * TEX_SIZE - 1 do
    begin
      Data[i * 2] := 255;
      Data[i * 2 + 1] := pix[i * 3];
    end;
    Font := Texture.NewTex(PChar('*Font_' + Name + '_' + IntToStr(Result) +
      '*'), Data,
      2, GL_LUMINANCE_ALPHA, TEX_SIZE, TEX_SIZE, 0, True, False);
    FreeMem(Data);
    List := glGenLists(256);
    for i := 0 to 255 do
    begin
      glNewList(List + Cardinal(i), GL_COMPILE);
      s := (i mod 16) / 16;
      t := (i div 16) / 16;
      GetTextExtentPoint32(MDC, @Char(i), 1, cs);
      Width[i] := cs.cx;
      glBegin(GL_QUADS);
      glTexCoord2f(s, 1 - t);
      glVertex2f(0, 0);
      glTexCoord2f(s + cs.cx / 512, 1 - t);
      glVertex2f(cs.cx, 0);
      glTexCoord2f(s + cs.cx / 512, 1 - t - cs.cy / 512);
      glVertex2f(cs.cx, cs.cy);
      glTexCoord2f(s, 1 - t - cs.cy / 512);
      glVertex2f(0, cs.cy);
      glEnd;
      glTranslatef(cs.cx, 0, 0);
      glEndList;
    end;
  end;

  Fonts[Result].Size := Size;
  DeleteObject(FNT);
  DeleteObject(BMP);
  DeleteDC(MDC);
  ReleaseDC(Window.Handle, DC);
end;

procedure TOpenGL.FontFree(Font: TFont);
begin
  if (Font >= Cardinal(Length(Fonts))) or (Fonts[Font] = nil) then
    Exit;
  Texture.Delete(Fonts[Font]^.Font);
  Fonts[Font]^.Font.UnLoad;
  glDeleteLists(Fonts[Font]^.List, 256);
  Dispose(Fonts[Font]);
  Fonts[Font] := nil;
end;

procedure TOpenGL.TextOut(Font: TFont; X, Y: Real; Text: PChar);
var
  str: string;
  i: Integer;
begin
  if (Font >= Cardinal(Length(Fonts))) or (Fonts[Font] = nil) then
    Exit;
  glPushAttrib(GL_ENABLE_BIT);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_LIGHTING);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GEQUAL, 0.1);
  Blend(BT_SUB);
  glListBase(Fonts[Font]^.List);
  Fonts[Font]^.Font.Enable;
  glPushMatrix;
  glTranslatef(X, Y, 0);
  str := Text;
  for i := 1 to Length(str) do
    glCallLists(1, GL_UNSIGNED_BYTE, @str[i]);
  glPopMatrix;
  glPopAttrib;
end;

procedure TOpenGL.Blend(BType: TBlendType);
begin
  if BType = BT_NONE then
    glDisable(GL_BLEND)
  else
  begin
    glEnable(GL_BLEND);
    case BType of
      // обычное смешивание
      BT_SUB: glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      // сложение
      BT_ADD: glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      // умножение
      BT_MULT: glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    end;
  end;
end;

function TOpenGL.ScreenShot(FileName: PChar): Boolean;
var
  F: HFile;
  pix: Pointer;
  TGA: packed record
    FileType: Byte;
    ColorMapType: Byte;
    ImageType: Byte;
    ColorMapStart: Word;
    ColorMapLength: Word;
    ColorMapDepth: Byte;
    OrigX: Word;
    OrigY: Word;
    iWidth: Word;
    iHeight: Word;
    iBPP: Byte;
    ImageInfo: Byte;
  end;

  BMP: packed record
    bfType: Word;
    bfSize: DWORD;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: DWORD;
    biSize: DWORD;
    biWidth: Integer;
    biHeight: Integer;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: DWORD;
    biSizeImage: DWORD;
    biXPelsPerMeter: Integer;
    biYPelsPerMeter: Integer;
    biClrUsed: DWORD;
    biClrImportant: DWORD;
  end;

begin
  Result := False;

  GetMem(pix, Window.Width * Window.Height * 3);
  glReadPixels(0, 0, Window.Width, Window.Height, GL_BGR, GL_UNSIGNED_BYTE,
    pix);

  F := FileCreate(FileName);
  if not FileValid(F) then
    Exit;

  if Copy(FileName, Length(FileName) - 2, 3) = 'tga' then
    with TGA, Window do
    begin
      FileType := 0;
      ColorMapType := 0;
      ImageType := 2;
      ColorMapStart := 0;
      ColorMapLength := 0;
      ColorMapDepth := 0;
      OrigX := 0;
      OrigY := 0;
      iWidth := Width;
      iHeight := Height;
      iBPP := 24;
      ImageInfo := 0;
      FileWrite(F, TGA, SizeOf(TGA));
    end
  else
    with BMP, Window do
    begin
      bfType := $4D42;
      bfSize := Width * Height * 3 + SizeOf(BMP);
      bfReserved1 := 0;
      bfReserved2 := 0;
      bfOffBits := SizeOf(BMP);
      biSize := SizeOf(BITMAPINFOHEADER);
      biWidth := Width;
      biHeight := Height;
      biPlanes := 1;
      biBitCount := 24;
      biCompression := 0;
      biSizeImage := Width * Height * 3;
      biXPelsPerMeter := 0;
      biYPelsPerMeter := 0;
      biClrUsed := 0;
      biClrImportant := 0;
      FileWrite(F, BMP, SizeOf(BMP));
    end;

  FileWrite(F, pix^, Window.Width * Window.Height * 3);
  FileClose(F);

  FreeMem(pix);
  Result := True;
end;

procedure TOpenGL.AddLog(Text: string);
begin
  Log.Print(Self, PChar(Text));
end;

procedure TOpenGL.GetPixelFormat;
var
  wglChoosePixelFormatARB: function(hdc: HDC; const piAttribIList: PGLint; const
    pfAttribFList: PGLfloat; nMaxFormats: GLuint; piFormats: PGLint;
      nNumFormats:
    PGLuint): BOOL; stdcall;
  fAttributes: array[0..1] of Single;
  iAttributes: array[0..11] of Integer;
  pfd: PIXELFORMATDESCRIPTOR;
  DC: Cardinal;
  hwnd: Cardinal;
  wnd: TWndClassEx;

  function GetFormat: Boolean;
  var
    Format: Integer;
    numFormats: Cardinal;
  begin
    iAttributes[7] := AASamples;
    if wglChoosePixelFormatARB(GetDC(hWnd), @iattributes, @fattributes, 1,
      @Format, @numFormats) and (numFormats >= 1) then
    begin
      AAFormat := Format;
      Result := True;
    end
    else
    begin
      dec(AASamples);
      Result := False;
    end;
  end;

label
  ext;
begin
  if AASamples = 0 then
    Exit;

  ZeroMemory(@wnd, SizeOf(wnd));
  with wnd do
  begin
    cbSize := SizeOf(wnd);
    lpfnWndProc := @DefWindowProc;
    hCursor := LoadCursor(0, IDC_ARROW);
    lpszClassName := 'eXAAtest';
  end;
  if RegisterClassEx(wnd) = 0 then
    Exit;

  hwnd := CreateWindow('eXAAtest', nil, WS_POPUP, 0, 0, 0, 0, 0, 0, 0, nil);
  DC := GetDC(hwnd);
  if DC = 0 then
    goto ext;

  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
  begin
    nSize := SizeOf(TPIXELFORMATDESCRIPTOR);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or
      PFD_SUPPORT_OPENGL or
      PFD_DOUBLEBUFFER;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 32;
    cDepthBits := 24;
    cStencilBits := 8;
    iLayerType := PFD_MAIN_PLANE;
  end;

  if not SetPixelFormat(DC, ChoosePixelFormat(DC, @pfd), @pfd) then
    goto ext;
  if not wglMakeCurrent(DC, wglCreateContext(DC)) then
    goto ext;

  fAttributes[0] := 0;
  fAttributes[1] := 0;

  iAttributes[0] := WGL_DRAW_TO_WINDOW_ARB;
  iAttributes[1] := 1;
  iAttributes[2] := WGL_SUPPORT_OPENGL_ARB;
  iAttributes[3] := 1;
  iAttributes[4] := WGL_SAMPLE_BUFFERS_ARB;
  iAttributes[5] := 1;
  iAttributes[6] := WGL_SAMPLES_ARB;
  iAttributes[8] := WGL_DOUBLE_BUFFER_ARB;
  iAttributes[9] := 1;
  iAttributes[10] := 0;
  iAttributes[11] := 0;

  wglChoosePixelFormatARB := wglGetProcAddress('wglChoosePixelFormatARB');
  if @wglChoosePixelFormatARB = nil then
    Exit;

  while (AASamples > 0) and (not GetFormat) do
    ; // смертельный номер!

  ext:
  ReleaseDC(hwnd, DC);
  DestroyWindow(hwnd);
  UnRegisterClass('eXAAtest', 0);
end;

function TOpenGL.Init: Boolean;
var
  pfd: PIXELFORMATDESCRIPTOR;
  iFormat: Integer;
begin
  Result := False;
  AddLog('init graphics core');
  DC := GetDC(Window.Handle);

  if DC = 0 then
  begin
    AddLog('Fatal Error "GetDC"');
    Exit;
  end;

  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
  begin
    nSize := SizeOf(TPIXELFORMATDESCRIPTOR);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or
      PFD_SUPPORT_OPENGL or
      PFD_DOUBLEBUFFER;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 32;
    cDepthBits := 24;
    cStencilBits := 8;
    iLayerType := PFD_MAIN_PLANE;
  end;

  if AAFormat > 0 then
    iFormat := AAFormat
  else
    iFormat := ChoosePixelFormat(DC, @pfd);
  if iFormat = 0 then
  begin
    AddLog('Fatal Error "ChoosePixelFormat"');
    Exit;
  end;

  if not SetPixelFormat(DC, iFormat, @pfd) then
  begin
    AddLog('Fatal Error "SetPixelFormat"');
    Exit;
  end;

  RC := wglCreateContext(DC);
  if RC = 0 then
  begin
    AddLog('Fatal Error "wglCreateContext"');
    Exit;
  end;

  if not wglMakeCurrent(DC, RC) then
  begin
    AddLog('Fatal Error "wglCreateContext"');
    Exit;
  end;
  // Инициализация доступных расширений
  ReadExtensions;
  // Настройка
  glDepthFunc(GL_LESS);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glClearColor(0, 0, 0, 0);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0);
  glViewport(0, 0, Window.Width, Window.Height);
  // Создание default текстуры и т.п.
  if not Texture.Init then
    Exit;
  // Создание Debug шрифта
  fnt_debug := FontCreate('FixedSys', 8);
  // Готово
  Result := True;
end;

procedure TOpenGL.ReadExtensions;
var
  i: Integer;
begin
  // Получаем адреса дополнительных процедур OpenGL
  AddLog('GL_VENDOR   : ' + glGetString(GL_VENDOR));
  AddLog('GL_RENDERER : ' + glGetString(GL_RENDERER));
  AddLog('GL_VERSION  : ' + glGetString(GL_VERSION));
  glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB, @i);
  AddLog('MAX_TEX_UNITS  : ' + IntToStr(i));
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @i);
  AddLog('MAX_TEX_SIZE   : ' + IntToStr(i));
  glGetIntegerv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, @GL_max_aniso);
  AddLog('MAX_ANISOTROPY : ' + IntToStr(GL_max_aniso));
  AddLog('USE_AA_SAMPLES : ' + IntToStr(AASamples));

  AddLog('Reading extensions');
  extension := glGetString(GL_EXTENSIONS);
  // Итак, нормальные люди (не извращенцы) которым
  // глубоко плевать на скорость запуска их приложений (игр)
  // производят поиск расширений стандартным методом
  // через строку GL_EXTENSIONS
  // Этот метод может съесть до нескольких секунд (проверено)
  // Эту "ерунду" я не смог пропусть, и сделал своё чёрное дело...
  // пробуем получить адрес процедуры принадлежащей нужному нам расширению
  // в случае успеха (<> nil) расширение существует и наоборот...
  // 1439 мс VS 229 мс на проверке 4 расширений :)

  // Управление вертикальной синхронизацией
  wglSwapIntervalEXT := wglGetProcAddress('wglSwapIntervalEXT');
  if @wglSwapIntervalEXT <> nil then
  begin
    AddLog('- WGL_EXT_swap_control'#9#9': Ok');
    WGL_EXT_swap_control := True;
    wglGetSwapIntervalEXT := wglGetProcAddress('wglGetSwapIntervalEXT');
  end
  else
    AddLog('- WGL_EXT_swap_control'#9#9': Fail');

  // Мультитекстурирование
  glActiveTextureARB := wglGetProcAddress('glActiveTextureARB');
  if @glActiveTextureARB <> nil then
  begin
    AddLog('- GL_ARB_multitexture'#9#9': Ok');
    GL_ARB_multitexture := True;
    glClientActiveTextureARB := wglGetProcAddress('glClientActiveTextureARB');
  end
  else
    AddLog('- GL_ARB_multitexture'#9#9': Fail');

  // рендер в текстуру
  glGenRenderbuffersEXT := wglGetProcAddress('glGenRenderbuffersEXT');
  if @glGenRenderbuffersEXT <> nil then
  begin
    AddLog('- GL_EXT_framebuffer_object'#9#9': Ok');
    GL_EXT_framebuffer_object := True;
    glDeleteRenderbuffersEXT := wglGetProcAddress('glDeleteRenderbuffersEXT');
    glBindRenderbufferEXT := wglGetProcAddress('glBindRenderbufferEXT');
    glRenderbufferStorageEXT := wglGetProcAddress('glRenderbufferStorageEXT');
    glGenFramebuffersEXT := wglGetProcAddress('glGenFramebuffersEXT');
    glDeleteFramebuffersEXT := wglGetProcAddress('glDeleteFramebuffersEXT');
    glBindFramebufferEXT := wglGetProcAddress('glBindFramebufferEXT');
    glFramebufferTexture2DEXT := wglGetProcAddress('glFramebufferTexture2DEXT');
    glFramebufferRenderbufferEXT :=
      wglGetProcAddress('glFramebufferRenderbufferEXT');
    glCheckFramebufferStatusEXT :=
      wglGetProcAddress('glCheckFramebufferStatusEXT');
  end
  else
    AddLog('- GL_EXT_framebuffer_object'#9#9': Fail');

  // шейдеры
  glDeleteObjectARB := wglGetProcAddress('glDeleteObjectARB');
  if @glDeleteObjectARB <> nil then
  begin
    AddLog('- GL_ARB_shading_language'#9#9': Ok');
    GL_ARB_shading_language := True;
    glCreateProgramObjectARB := wglGetProcAddress('glCreateProgramObjectARB');
    glCreateShaderObjectARB := wglGetProcAddress('glCreateShaderObjectARB');
    glShaderSourceARB := wglGetProcAddress('glShaderSourceARB');
    glAttachObjectARB := wglGetProcAddress('glAttachObjectARB');
    glLinkProgramARB := wglGetProcAddress('glLinkProgramARB');
    glUseProgramObjectARB := wglGetProcAddress('glUseProgramObjectARB');
    glCompileShaderARB := wglGetProcAddress('glCompileShaderARB');
    glGetObjectParameterivARB := wglGetProcAddress('glGetObjectParameterivARB');
    glGetAttribLocationARB := wglGetProcAddress('glGetAttribLocationARB');
    glGetUniformLocationARB := wglGetProcAddress('glGetUniformLocationARB');
    // attribs
    glVertexAttrib1fARB := wglGetProcAddress('glVertexAttrib1fARB');
    glVertexAttrib2fARB := wglGetProcAddress('glVertexAttrib2fARB');
    glVertexAttrib3fARB := wglGetProcAddress('glVertexAttrib3fARB');
    // uniforms
    glUniform1fARB := wglGetProcAddress('glUniform1fARB');
    glUniform2fARB := wglGetProcAddress('glUniform2fARB');
    glUniform3fARB := wglGetProcAddress('glUniform3fARB');
    glUniform1iARB := wglGetProcAddress('glUniform1iARB');
  end
  else
    AddLog('- GL_ARB_shading_language'#9#9': Fail');

  // VBO :)
  glBindBufferARB := wglGetProcAddress('glBindBufferARB');
  if @glBindBufferARB <> nil then
  begin
    AddLog('- GL_ARB_vertex_buffer_object'#9': Ok');
    GL_ARB_vertex_buffer_object := True;
    glBindBufferARB := wglGetProcAddress('glBindBufferARB');
    glDeleteBuffersARB := wglGetProcAddress('glDeleteBuffersARB');
    glGenBuffersARB := wglGetProcAddress('glGenBuffersARB');
    glBufferDataARB := wglGetProcAddress('glBufferDataARB');
    glBufferSubDataARB := wglGetProcAddress('glBufferSubDataARB');
  end
  else
    AddLog('- GL_ARB_vertex_buffer_object'#9': Fail');
end;

procedure TOpenGL.UnLoad;
begin
  FNPS.UnLoad;
  FontFree(fnt_debug);
  //== Высвобождение ресурсов
  if (DC <> 0) and (RC <> 0) then
  begin
    // Удаляем OpenGL контекст
    if RC <> 0 then
      wglDeleteContext(RC);
    // Удаляем графический контекст окна
    if DC <> 0 then
      ReleaseDC(Window.Handle, DC);
  end;
  inherited;
end;

function TOpenGL.FontHeigth(Font: TFont): Integer;
begin
  Result := Fonts[Font]^.Size * 2;
end;

function TOpenGL.TextLen(Font: TFont; Text: PChar): Integer;
var
  str: string;
  i: Integer;
begin
  Result := 0;
  if (Font >= Cardinal(Length(Fonts))) or (Fonts[Font] = nil) then
    Exit;
  str := Text;
  for i := 1 to Length(Text) do
    Result := Result + Fonts[Font]^.Width[Byte(str[i])];
end;

end.

