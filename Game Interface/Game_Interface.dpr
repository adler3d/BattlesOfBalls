program Game_Interface;
uses
  Windows,
  OpenGL,
  GameApp in 'GameApp.pas',
  Basa in 'Basa.pas',
  ASDSprites in 'ASDSprites.pas',
  ASDVector in 'ASDVector.pas',
  GameType in 'GameType.pas',
  GameTexture in 'GameTexture.pas',
  ASDLine in 'ASDLine.pas',
  ASDUtils in 'ASDEngine\ASDUtils.pas',
  ASDHeader in 'ASDEngine\ASDHeader.pas',
  ASDType in 'ASDEngine\ASDType.pas',
  GameTeam in 'GameTeam.pas',
  GameGraph in 'GameGraph.pas';

begin
  App:=TGameApp.Create;
  Engine.Run(UPS);
end.

