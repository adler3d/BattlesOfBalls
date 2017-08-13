program ASD_Test;
uses
  ASDHeader,
  ASDType,
  Windows,
  OpenGL,
  ASDUtils;

var
  V: Byte;
  X, Y: Integer;
  UPS: ICalcNPS;
  Imag: ITexImage;
  Back: ITexImage;

procedure Update;
begin
  UPS.Next;
  if Input[VK_Add] then
  begin
    Inc(V);
  end;
  if Input[VK_SUBTRACT] then
  begin
    Dec(V);
  end;
  if Input[VK_UP] then
  begin
    Dec(Y);
  end;
  if Input[VK_DOWN] then
  begin
    Inc(Y);
  end;
  if Input[VK_LEFT] then
  begin
    Dec(X);
  end;
  if Input[VK_RIGHT] then
  begin
    Inc(X);
  end;
  glClearColor(V / 256, 0, 0, 0);
  if Input[VK_ESCAPE] then
  begin
    Engine.Quit;
  end;
end;

{(*}// - No Format
procedure DrawQuads(Tex:ITexImage);
var
  W,H:Integer;
begin
  if Tex=nil then
    Exit;
  W:=Window.Width;
  H:=Window.Height;
  glPushMatrix;
  Tex.Enable;
  glColor3f(1,1,1);
  //glScalef(0.5,0.5,1);
  glBegin(GL_QUADS);
    glTexCoord2d(-1,-1);  glVertex2f(-W,-H);
    glTexCoord2d(1,-1);  glVertex2f(W,-H);
    glTexCoord2d(1,1);  glVertex2f(W,H);
    glTexCoord2d(-1,1);  glVertex2f(-W,H);
  glEnd;
  Tex.Disable;
  glPopMatrix;
end;
{*)}

procedure DrawText;
begin
  glPushMatrix;
  glColor3f(0, 0.8, 0.1);
  OGL.TextOut(0, X, Y, 'ASDEngine Test Program Run');
  glPopMatrix;
end;

procedure DrawRect;
var
  W,H:Integer;
  P:TPoint;
begin
  W:=50;
  H:=50;
  P:=Mouse.LastPosition;
  glPushMatrix;
  glTranslatef(P.X,P.Y,0);
  glColor4f(1,1,1,0.5);
  glBegin(GL_QUADS);
    glTexCoord2d(-1,-1);  glVertex2f(-W,-H);
    glTexCoord2d(1,-1);  glVertex2f(W,-H);
    glTexCoord2d(1,1);  glVertex2f(W,H);
    glTexCoord2d(-1,1);  glVertex2f(-W,H);
  glEnd;
  glPopMatrix;
end;

procedure Render;
begin
  OGL.Clear;
  //OGL.Set2D(0, 0, 100,100);
  OGL.Set2D(0, 0, Window.Width, Window.Height);
  OGL.Blend(BT_SUB);
  DrawQuads(Back);
  DrawQuads(Imag);
  DrawRect;
  //DrawGround;
  DrawText;

  glColor3f(0.8, 0.8, 0.1);
  OGL.TextOut(0, 8, 16, PChar('FPS: ' + IntToStr(OGL.FPS)));
  OGL.TextOut(0, 8, 32, PChar('UPS: ' + IntToStr(Round(UPS.NPS))));
  //OGL.TextOut(0, 8, 48, PChar('Name: ' + TGA.Name));
end;

procedure Quit;
begin
  if UPS <> nil then
    UPS.UnLoad;
end;

procedure InitProg;
begin
  X := 300;
  Y := 250;
  V := 0;
  UPS := Tools.InitCalcNPS(1000);
  Engine.RegProc(PROC_UPDATE, @Update);
  Engine.RegProc(PROC_RENDER, @Render);
  Engine.RegProc(PROC_QUIT, @Quit);
  Window.Mode(True, 1024, 768, 32, 85);
  Window.Create(Engine.Version, False);
  //OGL.VSync(True);
  glClearColor(V / 256, 0, 0, 0);
  OGL.Clear;
  Back := Texture.LoadFromFile('back.bmp');
end;

begin
  InitProg;
  Engine.Run(85);
end.

