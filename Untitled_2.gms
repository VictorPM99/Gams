set c item /c1*c3/
    p produto / p1*p3 /
    t per�odo / t1*t5 /
    i n�s / i1*i7 /
    r rotas / r1*r5/
;

alias(i,j,ii);

set conex (i,i)
/i1.i1, i1.i2, i1.i3, i1.i4, i1.i5, i1.i6, i1.i7,
 i2.i1, i2.i2, i2.i3, i2.i4, i2.i5, i2.i6, i2.i7,
 i3.i1, i3.i2, i3.i3, i3.i4, i3.i5, i3.i6, i3.i7,
 i4.i1, i4.i2, i4.i3, i4.i4, i4.i5, i4.i6, i4.i7,
 i5.i1, i5.i2, i5.i3, i5.i4, i5.i5, i5.i6, i5.i7,
 i6.i1, i6.i2, i6.i3, i6.i4, i6.i5, i6.i6, i6.i7,
 i7.i1, i7.i2, i7.i3, i7.i4, i7.i5, i7.i6, i7.i7/
;

display conex;

table d(p,ii) (dpi) demanda do produto p pelo cliente i

   i1  i2   i3   i4   i5   i6   i7
p1 0   10   40   60   70   85   0
p2 0   60   50   20   80   15   0
p3 0   100  35   70   20   30   0
;
table n(c,p) (ncp) unidades do item c usado para produzir o produto p

    p1   p2   p3
c1  2    2    2
c2  3    3    3
c3  4    4    4
;

parameters
w(c) (wc) largura do item c
/
  c1 20
  c2 30
  c3 25
/
l(c) (lc) comprimento do item c
/
  c1 40
  c2 35
  c3 50
/;

parameter h(c) (hc) custo de estocagem do item c;
h(c) = 0.001*w(c)*l(c);

parameter f(c) (fc) custo do setup de produ��o do item c;
f(c) = 1000*h(c);

parameter ro(c) (roc) tempo de processamento do item c;
ro(c) = w(c)*l(c)/2500;

parameter K(t) (Kt) capacidade de produ��o no per�odo t;
K(t) = (sum(c, ro(c)*sum(p, sum(ii, d(p,ii)*n(c,p)))))*3.5/card(t) ;

parameter Io(c) (Ioc) estoque inicial de c;
Io(c) =  sum(p, sum(ii, d(p,ii)*n(c,p)))/card(t);

parameter X(i) (Xi) coordenada X do n� i
/i1 0
 i2 100
 i3 300
 i4 500
 i5 400
 i6 400
 i7 0   /
;

parameter Y(i) (Yi) coordenada Y do n� i
/i1 0
 i2 200
 i3 300
 i4 500
 i5 400
 i6 800
 i7 0
/;

parameter X_(j) coordenada X do n� i
/i1 0
 i2 100
 i3 300
 i4 500
 i5 400
 i6 400
 i7 0   /
;

parameter Y_(j) coordenada Y do n� i
/i1 0
 i2 200
 i3 300
 i4 500
 i5 400
 i6 800
 i7 0
/;

parameter tal(i,j) (talij) tempo de viagem de n� i para o n� j;
tal(i,j) = (60/100)*(((X(i)-X_(j))**2 + (Y(i)-Y_(j))**2)**(1/2));

parameter ct(i,j) (cij) custo de viagem de n� i para o n� j;
ct(i,j) = (((X(i)-X_(j))**2 + (Y(i)-Y_(j))**2)**(1/2));

parameter fi(p) (fip) peso unit�rio do produto p;
fi(p) = 0.001*(sum(c, w(c)*l(c)*n(c,p)));

scalar teta capacidade do ve�culo;
teta = sum(p, sum(ii, d(p,ii)*fi(p)));

*janela de tempo do n� i1 at� i6 no per�odo t
parameter delta_inicial(t);
delta_inicial(t) = 480 + 1440*(ord(t) - 1);
parameter delta_final(t);
delta_final(t) = 1080 + 1440*(ord(t) - 1) ;

*janela de tempo do n� i7(dep�sito final) no per�odo t
parameter delta_depot_inicial(t);
delta_depot_inicial(t) = 1440*(ord(t) - 1);
parameter delta_depot_final(t);
delta_depot_final(t) = 1440*ord(t) ;

scalar lambda Tempo de descarregar ou carregar por unidade de peso  / 0.02/;

scalar delta data de vencimento do cliente i / [1080 + 1440*(card(t) - 1)]/ ;

scalar Rotas N�mero m�ximo de rotas no plano horizontal /[card(i) - 2]/;

parameter s(ii) tempo de servi�o do cliente i;
s(ii) = lambda*sum(p, fi(p)*d(p,ii));

parameter M_inicial(i,j) n�mero muito grande inicial;
M_inicial(i,j) $(ord(i) eq 1 and ord(j) gt 1 and ord(j) lt card(j)) = (1080 + 1440*(card(t) - 1)) + min(lambda*teta, sum(ii $(ord(ii) gt 1 and ord(ii) lt card(ii)), s(ii))) + tal(i,j) ;

parameter M(i,j) n�mero muito grande;
M(i,j) $(ord(i) gt 1 and ord(i) lt card(i) and ord(j) gt 1) = delta + s(i) + tal(i,j) ;

parameter Mc(c,t)  limite superior da quantidade de produ��o;
Mc(c,t) = min(K(t)/ro(c),sum(ii, sum(p, n(c,p)*d(p,ii))));

free variable z ;

*Lot-sizing vari�veis    (MUDAR O NOME DAS VARI�VEIS)
binary variable yy(c,t) igual a 1 se tive produ��o do item c no per�odo t caso contr�rio 0;
positive variable xx(c,t) quantidade de produ��o do item c no per�odo t;
positive variable Ic(c,t) invent�rio do item c no final do per�odo t ;

*Routing vari�veis
binary variable wo(i,j,r) igual a 1 se a rota r viajar diretamente do n� i para o n� j caso contr�rio 0  ;
positive variable Qo(p,r,t) quantidade do produto p enviado na rota r no per�odo t;
binary variable psi(i,r,t) igual a 1 se o n� i � visitado pela rota r no per�odo t caso contr�rio 0;
positive variable mi(i,r) tempo inicial em que o n� i � abastecido pela rota r;

equations
fo
Saldo_Estoque
Saldo_Estoque_Balanco
Estoque_Minimo
Capacidade_Producao
Producao_item
Partindo_Deposito
Chegando_Deposito
Conservacao_Fluxo
;

fo.. z =e= sum(c, sum(t, f(c)*yy(c,t))) +  sum(c, sum(t, h(c)*Ic(c,t))) + sum(i $(ord(i)<card(i)), sum(j $(ord(i) gt 1), sum(r, ct(i,j)*wo(i,j,r))));
Saldo_Estoque(c,t-1).. Ic(c,t) + xx(c,t) =e= sum(r, sum(p, n(c,p)*Qo(p,r,t) + Ic(c,t)));
Saldo_Estoque_Balanco(c,t).. Ic(c,t-1) =g= sum(r, sum(p, n(c,p)*Qo(p,r,t)));
Estoque_Minimo(c,t).. Ic(c,t) =g= Io(c);
Capacidade_Producao(t).. sum(c, ro(c)*xx(c,t)) =l= K(t);
Producao_item(c,t).. xx(c,t) =l= Mc(c,t)*yy(c,t);
Partindo_Deposito(i,j,r).. wo(i,j,r) $ (ord(i)eq 1)  =e= 1;
Chegando_Deposito(i,j,r).. wo (i,j,r) $ (ord(j) eq card(j)) =e= 1;
Conservacao_Fluxo(i,j,r).. w(i,j,r) =e= sum(w(j,i,r) $ (ord(j)<> ord(i) and ord(j) gt 1 and ord(j)< card(j)));




display w,c,h,f,ro,K,Io,X,Y,X_, Y_,Mc;
display tal, ct, fi, teta, delta_inicial, delta_final, delta_depot_inicial, delta_depot_final, lambda, delta, R,s,M_inicial,M ;