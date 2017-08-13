library ASDEngine;
{$R *.res}
{%File 'ASDEngine.dpr'}

uses
  Windows,
  ASDEng in 'ASDEng.pas',
  ASDInterface in 'ASDInterface.pas',
  ASDUtils in 'ASDUtils.pas',
  ASDSound in 'ASDSound.pas',
  ASDWindow in 'ASDWindow.pas',
  ASDLog in 'ASDLog.pas',
  ASDInput in 'ASDInput.pas',
  ASDOpenGL in 'ASDOpenGL.pas',
  ASDTexture in 'ASDTexture.pas',
  ASDBJG in 'ASDBJG.pas',
  ASDTGA in 'ASDTGA.pas',
  ASDClasses in 'ASDClasses.pas',
  ASDTools in 'ASDTools.pas';

{$E DLL}
Var
  OldProc:TDllProc;
const
  DLL_PROCESS_DETACH = 0;
  DLL_PROCESS_ATTACH = 1;
  DLL_THREAD_ATTACH  = 2;
  DLL_THREAD_DETACH  = 3;

Procedure DllExit(Reason:Integer);
begin
  if Reason=DLL_PROCESS_DETACH then
  begin
    Engine.UnLoad;
    Log.UnLoad;
    Halt;
  end;
  if Assigned(OldProc) then
    OldProc(Reason);
end;

procedure InitEngine(out Engine: IASDEngine; LogFile: PChar);
begin
  DllProc:=DllExit;
  Log := TLog.CreateEx;
  ASDEng.Engine := TASDEngine.CreateEx;
  Log.Create(LogFile);
  Engine := ASDEng.Engine;
end;

exports
  InitEngine;
begin

end.

