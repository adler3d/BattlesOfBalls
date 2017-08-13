unit GameTeam;

interface
uses
  Windows, Basa, ASDType, GameType, ASDHeader, ASDVector;

procedure InitTeam;
procedure SetupMonster(Bot: TTeamBot);
procedure Setup(Bot: TWeaponBot);
procedure SetupEx(Bot: TTeamBot);
function MakeBest: TLauncherBot;
function MakeWhite: TLauncherBot;
function MakeBlue: TLauncherBot;
function MakeRed: TLauncherBot;
function MakeLime: TLauncherBot;

function MakeBest2: TLauncherBot;
function MakeWhite2: TLauncherBot;
function MakeBlue2: TLauncherBot;
function MakeRed2: TLauncherBot;
function MakeLime2: TLauncherBot;

var
  TeamRed, TeamBlue, TeamLime, TeamWhite, TeamBest: TTeam;
implementation

uses
  GameApp;

procedure Setup(Bot: TWeaponBot);
var
  W, H, R: Real;
begin
  W := Window.Width;
  H := Window.Height;
  R := Bot.Radius + 1;
  Bot.Position := MakeVector(RndReal(R, W - R), RndReal(R, H - R));
  Bot.Vector := RndVector(1);
end;

procedure SetupEx(Bot: TTeamBot);
begin
  Setup(Bot);
  with TLauncherBot(Bot) do
  begin
    Life := 10;
    AmmoCount := 200;
    Priority := 25;
    ForceAmmo := 1;
  end;
end;

procedure InitTeam;
begin
  TeamRed := TTeam.Init(Game, clRed, 'Red');
  TeamBlue := TTeam.Init(Game, clBlue, 'Blue');
  TeamLime := TTeam.Init(Game, clLime, 'Lime');
  TeamWhite := TTeam.Init(Game, clWhite, 'White');
  TeamBest := TTeam.Init(Game, clYellow, 'Best');
end;

function MakeBest: TLauncherBot;
begin
  Result := TShotBot.Init(TeamBest);
  SetupEx(Result);
  with Result do
  begin
    Color := clYellow;
    Priority := 20;
  end;
end;

function MakeWhite: TLauncherBot;
begin
  Result := TLauncherBot.Init(TeamWhite);
  SetupEx(Result);
  with Result do
  begin
    Color := clWhite;
    Weapon := TRocketAmmo;
    Priority := 40;
  end;
end;

function MakeBlue: TLauncherBot;
begin
  Result := TShotBot.Init(TeamBlue);
  SetupEx(Result);
  with Result do
  begin
    Color := RGBA(128,128,255,255);
  end;
end;

function MakeRed: TLauncherBot;
begin
  Result := TShotBot.Init(TeamRed);
  SetupEx(Result);
  with Result do
  begin
    Color := RGBA(255,128,128,255);
  end;
end;

function MakeLime: TLauncherBot;
begin
  Result := TLauncherBot.Init(TeamLime);
  SetupEx(Result);
  with Result do
  begin
    Color := RGBA(128,255,128,255);
    Weapon := TRocketAmmo;
  end;
end;

procedure SetupEx2(Bot: TTeamBot);
begin
  Setup(Bot);
  with TLauncherBot(Bot) do
  begin
    Life := 10;
    AmmoCount := 200;
    Priority := 25;
    ForceAmmo := 1;
  end;
end;

procedure SetupMonster(Bot: TTeamBot);
begin
  Setup(Bot);
  with TLauncherBot(Bot) do
  begin
    Life := 500;
    AmmoCount := 1000;
    Priority := 20;
    ForceAmmo := 3;
    OnTimer:=App.DeadTimer;
    EnabledTimer:=True;
    Interval:=UPS*200;
    Radius:=Radius+2;
    Weapon:=TRocketAmmo;
  end;
end;

function MakeBest2: TLauncherBot;
begin
  Result := TBestBot.Init(TeamBest);
  SetupEx2(Result);
  with Result do
  begin
    Color := clYellow;
  end;
end;

function MakeWhite2: TLauncherBot;
begin
  Result := TLauncherBot.Init(TeamWhite);
  SetupEx2(Result);
  with Result do
  begin
    Color := clWhite;
    Weapon := TRocketAmmo;
  end;
end;

function MakeBlue2: TLauncherBot;
begin
  Result := TShotBot.Init(TeamBlue);
  SetupEx2(Result);
  with Result do
  begin
    Color := RGBA(128,128,255,255);
  end;
end;

function MakeRed2: TLauncherBot;
begin
  Result := TShotBot.Init(TeamRed);
  SetupEx2(Result);
  with Result do
  begin
    Color := RGBA(255,128,128,255);
  end;
end;

function MakeLime2: TLauncherBot;
begin
  Result := TLauncherBot.Init(TeamLime);
  SetupEx2(Result);
  with Result do
  begin
    Color := RGBA(128,255,128,255);
    Weapon := TRocketAmmo;
  end;
end;

end.

