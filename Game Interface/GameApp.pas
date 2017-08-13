unit GameApp;

interface

uses
  Windows,OpenGL,ASDHeader,ASDUtils,ASDType,Basa,GameType,ASDVector,
  GameTexture,ASDLine,GameTeam;

const
  UPS:Integer=100;

type
  TGameApp=class(TObject)
  private
    BackGround:ITexImage;
    FTag:Integer;
    NPS:ICalcNPS;
    Timer:ITimer;
    Bot:TLauncherBot;
    ATF:TAdlerTexFile;
    GameRec:TGameRec;
    Font:HFONT;
    FSelectBot:TLauncherBot;
    procedure DrawGround;
    procedure Make(S:string);
    procedure MakeResurce;
    procedure MouseDown(Button:TMouseButton; Shift:TShiftState; X,Y:Real);
    procedure SetSelectBot(const Value:TLauncherBot);
  public
    constructor Create;
    procedure InitGame;
    procedure InitWindow;
    procedure LoadTexture;
    procedure InitBot;
    procedure InitMap;
    procedure DoTimer;
    procedure DoTimer2;
    procedure DoText;
    procedure Income;
    procedure DeadTimer(Sender:TWeaponBot);
    property SelectBot:TLauncherBot read FSelectBot write SetSelectBot;
    property Tick:Integer read FTag;
  end;

procedure Update;
procedure Render;
procedure Quit;
procedure Activate(Active:Boolean);

var
  Game:TGameEngine;
  App:TGameApp;
  Start:Boolean;
const
  MaxTick:Integer=500*1000*10;

implementation

uses ASDSprites;

function GetBotFromPosition(Pos:TVector):TLauncherBot;
var
  I:Integer;
begin
  for I:=0 to Game.Bots.Count-1 do
  begin
    Result:=TLauncherBot(Game.Bots[I]);
    if VectorMagnitude(VectorSub(Result.Position,Pos))<Result.Radius*2 then Exit;
  end;
  Result:=nil;
end;

procedure Update;
begin
  if Input[VK_ESCAPE] then
  begin
    Engine.Quit;
  end;
  if App.NPS.AllTick>MaxTick then
    Exit;
  App.Timer.Start;
  App.NPS.Next;
  App.DoTimer2;
  Game.Move;
  Game.CollisionRect;
  Game.CollisionAmmo;
  Game.CollisionBot;
  Game.Dead;
  Mouse.Update;
  if App.SelectBot<>nil then if App.SelectBot.Deaded then App.SelectBot:=nil;
  if (App.Tick mod (UPS*30))=0 then
    App.Income;
  App.Timer.Stop;
  App.GameRec.UpdateTime:=App.Timer.Time;
end;

procedure Render;
begin
  App.Timer.Start;
  glClearColor(0,0,0,0);
  OGL.Clear;
  OGL.Set2D(0,0,Window.Width,Window.Height);
  OGL.Blend(BT_SUB);
  App.DrawGround;
  Game.Draw;
  if App.SelectBot<>nil then
  begin
    DrawQuads(SelBox,App.SelectBot.Position,App.SelectBot.Team.TeamColor,14+2*Sin(App.FTag*2*pi/UPS),App.FTag);
  end;
  glColor3f(1,1,1);
  App.DoText;
  App.Timer.Stop;
  App.GameRec.RenderTime:=App.Timer.Time;
end;

procedure Quit;
begin
  Game.Free;
  App.NPS.UnLoad;
  App.Timer.UnLoad;
end;

procedure Activate(Active:Boolean);
begin
  Start:=True;
end;

procedure Overflow(Sys:Cardinal);
begin
  Start:=Sys=SYS_UPS_IN;
end;

{ TProgSystem }

procedure TGameApp.InitWindow;
var
  SM:TScreenMode;
begin
  SM:=GetScreenMode;
  Start:=True;
  Window.Create(Engine.Version,False);
  Window.Mode(True,SM.X,SM.Y,SM.BPP,SM.Freg);
  Font:=OGL.FontCreate('Courier New',10);
  //  OGL.VSync(True);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  InitGame;
end;

constructor TGameApp.Create;
begin
  App:=Self;
  Engine.ActiveUpdate(True);
  Engine.RegProc(PROC_UPDATE,@Update);
  Engine.RegProc(PROC_RENDER,@Render);
  Engine.RegProc(PROC_QUIT,@Quit);
  Engine.RegProc(PROC_ACTIVE,@Activate);
  Engine.RegProc(PROC_OVERFLOW, @Overflow);
  InitWindow; SelectBot:=nil;
end;

{(*}
procedure TGameApp.DrawGround;
var
  W,H:Single;
  SW,SH:Single;
begin
  W:=Window.Width;
  H:=Window.Height;
  if BackGround<>nil then
  begin
    SW:=W/BackGround.Width;
    SH:=H/BackGround.Height;
    //SW:=1;
    //SH:=1;
  end;
  glPushMatrix;
  if BackGround<>nil then
  begin
    BackGround.Enable;
    glColor3f(1,1,1);
    glBegin(GL_QUADS);
      glTexCoord2f(0,0);  glVertex2f(0,0);
      glTexCoord2f(SW,0);  glVertex2f(W,0);
      glTexCoord2f(SW,SH);  glVertex2f(W,H);
      glTexCoord2f(0,SH);  glVertex2f(0,H);
    glEnd;
    BackGround.Disable;
  end;
  {glColor3f(0,1,0);
  glBegin(GL_LINE_LOOP);
    glVertex2f(0,1);
    glVertex2f(W-1,1);
    glVertex2f(W-1,H);
    glVertex2f(0,H);
  glEnd;}
  glPopMatrix;
end;
{*)}

procedure TGameApp.DoText;
var
  X,Y,I:Integer;
  Team:TTeam;
  procedure NextText(Name:string; C:TRGBA);
  begin
    glColor4ubv(@C);
    OGL.TextOut(Font,X,Y,PChar(Name));
    Inc(Y,14);
  end;
  procedure NextTextR(Name:string; Value:Real; C:TRGBA);
  begin
    NextText(Name+' : '+FloatToStr(Value,2,2),C);
  end;
  procedure NextTextI(Name:string; Value:Integer; C:TRGBA);
  begin
    NextText(Name+' : '+IntToStr(Value),C);
  end;
  procedure NextTextISIS(Name:string; V1,V2:Integer; E1,E2:string; C:
    TRGBA);
  begin
    NextText(Name+' : '+IntToStr(V1)+E1+'|'+IntToStr(V2)+E2,C);
  end;
begin
  glPushMatrix;
  X:=8;
  Y:=16;
  NextTextR('FPS',OGL.FPS,clWhite);
  NextTextR('UPS',NPS.NPS,clWhite);
  Inc(Y,16);
  NextTextI('Tick',NPS.AllTick,clWhite);
  if not Start then
  begin
    glColor4ubv(@clRed);
    OGL.TextOut(Font,250,16,PChar('Падение производительности !'));
  end;
  Inc(Y,16);
  NextTextI('Bots.Count',Game.Bots.Count,clWhite);
  NextTextI('Ammos.Count',Game.Ammos.Count,clWhite);
  NextTextI('Animi.Count',Game.Animi.Count,clWhite);
  Inc(Y,16);
  NextTextI('Bots.AllCount',Game.Bots.AllCount,clLime);
  NextTextI('Ammos.AllCount',Game.Ammos.AllCount,clLime);
  NextTextI('Animi.AllCount',Game.Animi.AllCount,clLime);
  Inc(Y,16);
  if SelectBot<>nil then
  begin
    //OGL.TextOut(Font,X,Y,PChar('SelectBot is '
    NextText('SelectBot '+SelectBot.Caption,SelectBot.Color);
    
    NextTextR('SelectBot.Life',SelectBot.Life,SelectBot.Color);
    NextTextR('SelectBot.ForceAmmo',SelectBot.ForceAmmo,SelectBot.Color);
    NextTextR('SelectBot.Speed',VectorMagnitude(SelectBot.Vector),SelectBot.Color);
    NextTextR('SelectBot.LifeTime',(FTag-SelectBot.TickCreate)/100,SelectBot.Color);
    NextTextI('SelectBot.AllAmmo',SelectBot.AllAmmo,SelectBot.Color);
    NextTextI('SelectBot.Priority',SelectBot.Priority,SelectBot.Color);
    NextTextI('SelectBot.AmmoCount',SelectBot.AmmoCount,SelectBot.Color);
    NextTextI('SelectBot.Frag',SelectBot.FragCount,SelectBot.Color);
  end else NextText('SelectBot not found',clYellow);

  X:=Window.Width-450;
  Y:=16;
  NextTextR('Render Time',GameRec.RenderTime,clWhite);
  NextTextR('Update Time',GameRec.UpdateTime,clWhite);
  NextTextISIS('Mouse Position',Mouse.LastPosition.X,Mouse.LastPosition.Y,'x','y',clYellow);

  X:=Window.Width-175;
  Y:=16;
  for I:=0 to Game.Team.Count-1 do
  begin
    Team:=Game.Team[I];
    NextTextISIS(Team.Name,Team.BotCount,Team.FragCount,'','',Team.TeamColor);
  end;
  glPopMatrix;
end;

procedure TGameApp.Make(S:string);
begin
  ATF.LoadFromSource(S+'.bmp',S+'Mask.bmp');
  ATF.SaveToFile(S+'.ATF');
end;

procedure TGameApp.LoadTexture;
begin
  //BackGround := Texture.LoadFromFile('Back.bmp');
  BotTex:=ATF.LoadFromFile('Bot.ATF');
  AmmoTex:=ATF.LoadFromFile('Ammo.ATF');
  RocketTex:=ATF.LoadFromFile('Rocket.ATF');
  TeamTex:=ATF.LoadFromFile('Team.ATF');
  ExplosionTex:=ATF.LoadFromFile('Explosion.ATF');
  SparkTex:=ATF.LoadFromFile('Spark.ATF');
  SelBox:=ATF.LoadFromFile('SelBox.ATF');
  LeaderTex:=ATF.LoadFromFile('Leader.ATF');
  AmmoTex:=AmmoTex;
end;

procedure TGameApp.MakeResurce;
begin
  ATF:=TAdlerTexFile.Create;
  if ParamCount>0 then
  begin
    if ParamStr(1)='-Debug' then
    begin
      Window.Caption(PChar(Engine.Version+'[Debug]'));
    end;
    if ParamStr(1)='-Low' then
    begin
      Game.Animi.Visible:=False;
      Game.Animi.Moved:=False;
    end;
    if ParamStr(1)='-MakeRes' then
    begin
      Make('Bot');
      Make('Ammo');
      Make('Rocket');
      Make('Team');
      Make('Explosion');
      Make('Spark');
      Make('SelBox');
      Make('Leader');
      Engine.Quit;
    end;
  end;
end;

procedure TGameApp.InitGame;
begin
  Randomize;
  Game:=TGameEngine.Init;
  MakeResurce;
  LoadTexture;
  NPS:=Tools.InitCalcNPS(1000);
  Timer:=Tools.InitTimer;
  Mouse.OnMouseDown:=MouseDown;
  InitTeam;
  InitBot;
  InitMap;
end;

procedure TGameApp.InitBot;
var
  I:Integer;
  Last:TLauncherBot;
begin
  (*for I:=1 to 3 do
  begin
    Last:=MakeRed; //Last.Life:=2; Last.ForceAmmo:=2; Last.AmmoCount:=10;
    Last:=MakeBlue; //Last.Life:=0; Last.ForceAmmo:=0.5; Last.AmmoCount:=10;
    Last:=MakeLime; //Last.Life:=1; Last.ForceAmmo:=4; Last.AmmoCount:=10;
    Last:=MakeWhite; //Last.Life:=4; Last.ForceAmmo:=1; Last.AmmoCount:=0;
  end;
  Last:=MakeBest;
  Last.Color:=RGBA(255,255,150,150);
  Last.Vector:=NulVector;
  {}
  Last:=MakeWhite;
  Last.Color:=RGBA(200,200,255,200);
  Last.Vector:=NulVector;*)
end;

procedure TGameApp.DoTimer;
var
  Last:TLauncherBot;
begin
  Inc(FTag);
  if (FTag mod (UPS*1000))>(UPS*900) then Exit;
  if (FTag mod(UPS*30))=0 then
  begin
    Bot:=MakeBest;
  end;
  if (FTag mod(UPS*2))=0 then
  begin
    Bot:=MakeWhite;
  end;
  if ((FTag)mod(UPS*2))=0 then
  begin
    Last:=MakeBlue;
    Last:=MakeRed;
  end;
  if (FTag mod(UPS*2))=0 then
  begin
    Last:=MakeLime;
  end;
  if ((FTag mod(UPS*90))>(UPS*85))and((FTag mod(UPS*90))<(UPS*90))
    and((FTag*5 mod UPS)=0) then
  begin
    Last:=MakeBlue;
    Last:=MakeRed;
  end; {and((FTag mod(UPS*600))<(UPS*600))}
  if ((FTag mod(UPS*600)>(UPS*590))and((FTag*5 mod UPS)=0)) then
  begin
    Last:=MakeWhite; Last.Life:=20;
  end;
end;

procedure TGameApp.DoTimer2;
var
  Last:TLauncherBot;
begin
  Inc(FTag);   //if FTag>1000 then Exit;
  if (FTag mod (UPS*1000))=(UPS*800) then
  begin
    Last:=TLauncherBot.Init(TeamRed); SetupMonster(Last);
    Last:=TLauncherBot.Init(TeamBlue); SetupMonster(Last);
    Last:=TLauncherBot.Init(TeamBest); SetupMonster(Last);
    Last:=TLauncherBot.Init(TeamLime); SetupMonster(Last);
    Last:=TLauncherBot.Init(TeamWhite); SetupMonster(Last);  
  end;
  if (FTag mod (UPS*1000))>(UPS*700) then Exit;
  if (FTag mod(UPS*2))=0 then
  begin
    Last:=MakeBest2;
    Last:=MakeWhite2;
    Last:=MakeBlue2;
    Last:=MakeRed2;
    Last:=MakeLime2;
  end;
end;

procedure TGameApp.InitMap;
const
  H:Real=100; //размер щели
  D:Real=100; // Дырка в стенке
var
  V1,V2:TVector;
  V1N,VN4,V2N,VN3:TVector;
  VFM,VLM:TVector;
  V5,V7,V8,V6:TVector;
  V4,V3:TVector;
  Temp:TLineBot;
  procedure Add(A,B:TVector);
  begin
    Temp.A:=A;
    Temp.B:=B;
    Game.Lines.Add(Temp);
  end;
begin
  Temp.F:=lfCollision;
  Temp.C:=RGBA(128,255,128,255);
  V1:=NulVector;
  V2:=MakeVector(Window.Width,0);
  V3:=MakeVector(Window.Width,Window.Height);
  V4:=MakeVector(0,Window.Height);
  V5:=MakeVector(0,Window.Height/2);
  V6:=MakeVector(Window.Width,Window.Height/2);
  V7:=MakeVector((Window.Width/2)-H/2,Window.Height/2);
  V8:=MakeVector((Window.Width/2)+H/2,Window.Height/2);
  V1N:=MakeVector(0,(Window.Height/2)-D/2);
  VN4:=MakeVector(0,(Window.Height/2)+D/2);
  V2N:=MakeVector(Window.Width,(Window.Height/2)-D/2);
  VN3:=MakeVector(Window.Width,(Window.Height/2)+D/2);
  VFM:=MakeVector(-Window.Width*2,(Window.Height/2));
  VLM:=MakeVector(+Window.Width*3,(Window.Height/2));
  //Рамка
  Add(V1,V2);
  Add(V2,V3);
  Add(V3,V4);
  Add(V4,V1);
  //Перегородка
  {Add(V5,V7);
  Add(V8,V6);}
  //Дрявая стена
  {Add(V1, V2);
  Add(V1, V1N);
  Add(VN4, V4);
  Add(V2, V2N);
  Add(VN3, V3);
  Add(V4, V3);}
  //конусы
  {Add(V1N, VFM);
  Add(VN4, VFM);
  Add(V2N, VLM);
  Add(VN3, VLM);}
end;

procedure TGameApp.SetSelectBot(const Value:TLauncherBot);
begin
  if Value=FSelectBot then Exit;
  if FSelectBot<>nil then FSelectBot.UnLock;
  FSelectBot:=Value;
  if FSelectBot<>nil then FSelectBot.Lock;
end;

procedure TGameApp.MouseDown(Button:TMouseButton; Shift:TShiftState; X,
  Y:Real);
begin
  if Button<>mbLeft then
  begin
    if App.SelectBot=nil then Exit;
    //App.SelectBot.Vector:=NulVector;
  end;
  App.SelectBot:=GetBotFromPosition(PointToVector(Mouse.LastPosition));
end;

procedure TGameApp.Income;
var
  I:Integer;
  B:TLauncherBot;
begin
  for I:=0 to Game.Bots.Count-1 do
  begin
    B:=TLauncherBot(Game.Bots[I]);
    B.AmmoCount:=B.AmmoCount+10;
    B.Life:=B.Life+1.0;
  end;
end;

procedure TGameApp.DeadTimer(Sender: TWeaponBot);
begin
  Sender.Dead; TSparks.Init(Sender,50);
end;

end.

