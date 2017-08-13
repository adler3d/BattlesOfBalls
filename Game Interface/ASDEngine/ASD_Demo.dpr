program ASD_Demo;
uses
  ASDHeader,
  ASDType,
  Windows,
  OpenGL,
  ASDUtils;

var
  Obj: GLUquadricObj;
  Angle: Single;
  Font: Cardinal;
  startList: Cardinal;
  Slices, Loops: Integer;

procedure Update;
begin
  Angle := Angle + 0.01;
  if Input[VK_ESCAPE] then
    Engine.Quit;
  if Input[VK_F12] then
    OGL.ScreenShot('SH.bmp');
  if Input[VK_Q] then
  begin
    Slices := Slices + 1;
    Input.DelKey(VK_Q);
  end;
  if Input[VK_W] then
  begin
    Slices := Slices - 1;
    Input.DelKey(VK_W);
  end;
  if Input[VK_A] then
  begin
    Loops := Loops + 1;
    Input.DelKey(VK_A);
  end;
  if Input[VK_S] then
  begin
    Loops := Loops - 1;
    Input.DelKey(VK_S);
  end;
end;

procedure Render;
var
  i: Integer;
begin
  OGL.Clear(True, True);
  OGL.Set3D(90, 0.1, 5000);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);

  //OGL.Blend(BT_ADD);
  glTranslatef(0, 0, -16);

  glPushMatrix;
  glColor3f(0.1, 0.8, 0.1);
  glRotatef(Angle * 180 / Pi, sin(Angle), cos(Angle), sin(Angle));
  gluQuadricDrawStyle(obj, GLU_SILHOUETTE);
  gluSphere(Obj, 5, Slices, Loops);
  glPopMatrix;

  glPushMatrix;
  glColor3f(0.8, 0.8, 0.1);
  glTranslatef(12, 0, 0);
  glRotatef(Angle * 180 / Pi, sin(Angle), cos(Angle), sin(Angle));
  glCallList(startList);
  glPopMatrix;

  glPushMatrix;
  glColor3f(0.1, 0.8, 0.8);
  glTranslatef(-12, 0, 0);
  glRotatef(Angle * 180 / Pi, sin(Angle), cos(Angle), sin(Angle));
  glCallList(startList);
  glPopMatrix;

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);
  OGL.Set2D(0, 0, Window.Width, Window.Height);
  glColor3f(0.1, 0.8, 0.1);
  OGL.TextOut(Font, 8, 16, PChar('FPS: ' + IntToStr(OGL.FPS)));
end;

procedure GenObj;
begin
  StartList := glGenLists(1);
  Obj := gluNewQuadric();
  glDisable(GL_SMOOTH);
  gluQuadricDrawStyle(obj, GLU_FILL);
  gluQuadricNormals(obj, GLU_SMOOTH);
  //glColor3f(0,1,0);
  glNewList(startList, GL_COMPILE);
  gluSphere(obj, 5, 10, 10);
  glEndList();
end;

procedure Init;
begin
  Loops := 13;
  Slices := 23;
  Font := OGL.FontCreate('Comic Sans MS', 16);
  glDisable(GL_CULL_FACE);
  glEnable(GL_LIGHT0);
  GenObj;
end;

begin
  OGL.AntiAliasing(4);
  Engine.RegProc(PROC_UPDATE, @Update);
  Engine.RegProc(PROC_RENDER, @Render);
  Window.Create(PChar(Engine.Version + ' demo'), False);
  Window.Mode(True, 1024, 768, 32, 85);
//  OGL.VSync(True);
  Init;
  Engine.Run(50);
end.

