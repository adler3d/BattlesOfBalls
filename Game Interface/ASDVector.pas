unit ASDVector;
{<|Author : Adler3D|>}
{<|e-mail : Adler3D@mail.ru|>}
{<|site : Adler3D.narod.ru|>}
interface
{$D-}
uses Windows;

type
  PVector=^TVector;
  TVector=record
    X,Y:Real;
  end;

  PVectorAngle=^TVectorAngle;
  TVectorAngle=record
    Alfa,Dlina:Real;
  end;

  PLine=^TLine;
  TLine=record
    A,B:TVector;
  end;

function MakeVector(X,Y:Real):TVector;
function MakeVectorEx(Angle,Mag:Real):TVector;
function MakeVectorAngle(Alfa,Dlina:Real):TVectorAngle;
function MakeLine(A,B:TVector):TLine;

function VectorAdd(A,B:TVector):TVector;
function VectorMul(V:TVector; Value:Real):TVector;
function VectorDiv(V:TVector; Value:Real):TVector;
function VectorSub(A,B:TVector):TVector;

function VectorMagnitude(V:TVector):Real;
function VectorGetAlfa(V:TVector):Real;

function VectorAngleToVector(V:TVectorAngle):TVector;
function VectorToVectorAngle(V:TVector):TVectorAngle;

function VectorNormal(V:TVector):TVector;

function VectorSetAlfa(V:TVector; Alfa:Real):TVector;
function VectorAddAlfa(V:TVector; Alfa:Real):TVector;
function VectorSetDlina(V:TVector; Dlina:Real):TVector;
function VectorAddDlina(V:TVector; Dlina:Real):TVector;

function VectorEqual(V1,V2:TVector):Boolean;

function RndReal(Min,Max:Real; Step:Real=0.0001):Real;
function RndVector(MaxMag:Real=1; MinMag:Real=0; Step:Real=0.001):TVector;

function VectorToPoint(V:TVector):TPoint;
function PointToVector(P:TPoint):TVector;

function VectorCompareAlfa(VA,VB:TVector):Real;
function VectorCompareDlina(VA,VB:TVector):Real;

function VectorABDlina(A,B:TVector):Real;

function VectorRot(Vec,Base:TVector):TVector;
function VectorUnRot(Vec,Base:TVector):TVector;

function ArcTan2(const Y,X:Extended):Extended;
procedure SinCos(const Theta:Extended; var Sin,Cos:Extended);

function VectorCross(A,B:TVector):Real;

const
  NulVectorAngle:TVectorAngle=(Alfa:0; Dlina:0);
  NulVector:TVector=(X:0.000; Y:0.000);
  PI2:Real=Pi*2;
  PID2:Real=Pi/2;
implementation

function VectorCross(A,B:TVector):Real;
begin
  Result:=A.X*B.Y-B.X*A.Y;
end;

function VectorRot(Vec,Base:TVector):TVector;
var
  M:Real;
begin
  Result:=NulVector;
  M:=Sqrt((Base.X)*(Base.X)+(Base.Y)*(Base.Y));
  if M=0 then Exit;
  Result.X:=((Vec.X*Base.X)+(Vec.Y*Base.Y))/M;
  Result.Y:=((Vec.X*-Base.Y)+(Vec.Y*Base.X))/M;
end;

function VectorUnRot(Vec,Base:TVector):TVector;
var
  M:Real;
begin
  Result:=NulVector;
  M:=Sqrt((Base.X)*(Base.X)+(Base.Y)*(Base.Y));
  if M=0 then Exit;
  Result.X:=((Vec.X*Base.X)+(Vec.Y*-Base.Y))/M;
  Result.Y:=((Vec.X*Base.Y)+(Vec.Y*Base.X))/M;
end;

procedure SinCos(const Theta:Extended; var Sin,Cos:Extended);
asm
        FLD     Theta
        FSINCOS
        FSTP    tbyte ptr [edx]    // Cos
        FSTP    tbyte ptr [eax]    // Sin
        FWAIT
end;

function ArcTan2(const Y,X:Extended):Extended;
asm
        FLD     Y
        FLD     X
        FPATAN
        FWAIT
end;

function VectorABDlina(A,B:TVector):Real;
begin
  Result:=Sqrt(Sqr(A.X-B.X)+Sqr(A.Y-B.Y));
end;

function RndReal(Min,Max:Real; Step:Real=0.0001):Real;
begin
  Result:=Random(Round((Max-Min)/Step))*Step+Min;
end;

function RndVector(MaxMag,MinMag,Step:Real):TVector;
var
  A,M:Real;
begin
  A:=RndReal(0,Pi*2,Step); M:=RndReal(MinMag,MaxMag,Step);
  Result.X:=M*Cos(A); Result.Y:=M*Sin(A);
end;

function VectorToPoint(V:TVector):TPoint;
begin
  Result.X:=Round(V.X);
  Result.Y:=Round(V.Y);
end;

function PointToVector(P:TPoint):TVector;
begin
  Result.X:=P.X;
  Result.Y:=P.Y;
end;

function VectorEqual(V1,V2:TVector):Boolean;
begin
  Result:=(V1.X=V2.X)and(V1.Y=V2.Y);
end;

function VectorSetDlina(V:TVector; Dlina:Real):TVector;
var
  K:Real;
begin
  K:=Dlina/Sqrt((V.X*V.X)+(V.Y*V.Y));
  Result.X:=V.X*K;
  Result.Y:=V.Y*K;
end;

function VectorAddDlina(V:TVector; Dlina:Real):TVector;
var
  K:Real;
begin
  K:=Dlina/Sqrt((V.X*V.X)+(V.Y*V.Y));
  Result.X:=V.X+(V.X*K);
  Result.Y:=V.Y+(V.Y*K);
end;

function VectorSetAlfa(V:TVector; Alfa:Real):TVector;
var
  M:Real;
  S,C:Extended;
begin
  M:=Sqrt((V.X*V.X)+(V.Y*V.Y));
  SinCos(Alfa,S,C);
  Result.X:=M*C;
  Result.Y:=M*S;
end;

function VectorAddAlfa(V:TVector; Alfa:Real):TVector;
var
  S,C:Extended;
begin
  SinCos(Alfa,S,C);
  Result.X:=V.X*C-V.Y*S;
  Result.Y:=V.X*S+V.Y*C;
end;

function VectorNormal(V:TVector):TVector;
begin
  Result.Y:=Sqrt((V.X*V.X)+(V.Y*V.Y));
  if Result.Y=0 then
  begin
    Result.X:=0;
    Exit;
  end;
  Result.X:=V.X/Result.Y;
  Result.Y:=V.Y/Result.Y;
end;

function MakeVectorAngle(Alfa,Dlina:Real):TVectorAngle;
begin
  Result.Alfa:=Alfa;
  Result.Dlina:=Dlina;
end;

function VectorAngleToVector(V:TVectorAngle):TVector;
begin
  Result.X:=Cos(V.Alfa)*V.Dlina;
  Result.Y:=Sin(V.Alfa)*V.Dlina;
end;

function VectorToVectorAngle(V:TVector):TVectorAngle;
begin
  Result.Alfa:=ArcTan2(V.Y,V.X);
  Result.Dlina:=Sqrt((V.Y*V.Y)+(V.X*V.X));
end;

function MakeVector(X,Y:Real):TVector;
begin
  Result.X:=X;
  Result.Y:=Y;
end;

function MakeVectorEx(Angle,Mag:Real):TVector;
var
  S,C:Extended;
begin
  SinCos(Angle,S,C);
  Result.X:=C*Mag;
  Result.Y:=S*Mag;
end;

function VectorAdd(A,B:TVector):TVector;
begin
  Result.X:=A.X+B.X;
  Result.Y:=A.Y+B.Y;
end;

function VectorMul(V:TVector; Value:Real):TVector;
begin
  Result.X:=V.X*Value;
  Result.Y:=V.Y*Value;
end;

function VectorDiv(V:TVector; Value:Real):TVector;
begin
  Result.X:=V.X/Value;
  Result.Y:=V.Y/Value;
end;

function VectorMagnitude(V:TVector):Real;
begin
  Result:=Sqrt((V.X*V.X)+(V.Y*V.Y));
end;

function VectorGetAlfa(V:TVector):Real;
begin
  Result:=ArcTan2(V.Y,V.X);
end;

function VectorSub(A,B:TVector):TVector;
begin
  Result.X:=A.X-B.X;
  Result.Y:=A.Y-B.Y;
end;

{function VectorToStr(V: TVector): string;
begin
  Result := 'X:' + FloatToStrF(V.X, ffFixed, 8, 16);
  Result := Result + ' Y:' + FloatToStrF(V.Y, ffNumber, 8, 16);
end;

function StrToVector(S: string): TVector;
var
  P: Integer;
  S1, S2: string;
begin
  P := Pos(' ', S);
  S1 := Copy(S, 3, P - 3);
  S2 := Copy(S, P + 3, 128);
  Result.X := StrToFloat(S1);
  Result.Y := StrToFloat(S2);
end;}

function VectorCompareAlfa(VA,VB:TVector):Real;
var
  A,B:Real;
begin
  A:=ArcTan2(VA.Y,VA.X);
  B:=ArcTan2(VB.Y,VB.X);
  if Abs(A-B)>=Pi then
  begin
    if A<B then
      A:=A+(2*Pi)
    else
      B:=B+(2*Pi);
  end;
  Result:=A-B;
end;

function VectorCompareDlina(VA,VB:TVector):Real;
var
  A,B:Real;
begin
  A:=VectorMagnitude(VA);
  B:=VectorMagnitude(VB);
  Result:=A-B;
end;

function MakeLine(A,B:TVector):TLine;
begin
  Result.A:=A;
  Result.B:=B;
end;

end.

