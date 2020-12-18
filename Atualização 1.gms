*The operator ord returns the relative position of a member in a set.

*The operator card returns the number of elements in a set.

set c item /c1*c3/
    p produto / p1*p3 /
    t período / t1*t5 /
    i nós / i1*i7 /
    r rotas / r1*r5/
;

alias(i,j,ii,ki);

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

parameter f(c) (fc) custo do setup de produção do item c;
f(c) = 1000*h(c);

parameter ro(c) (roc) tempo de processamento do item c;
ro(c) = w(c)*l(c)/2500;

parameter K(t) (Kt) capacidade de produção no período t;
K(t) = (sum(c, ro(c)*sum(p, sum(ii, d(p,ii)*n(c,p)))))*3.5/card(t) ;

parameter Io(c) (Ioc) estoque inicial de c;
Io(c) =  sum(p, sum(ii, d(p,ii)*n(c,p)))/card(t);

parameter X_(i) (Xi) coordenada X do nó i
/i1 0
 i2 100
 i3 300
 i4 500
 i5 400
 i6 400
 i7 0   /
;

parameter Y_(i) (Yi) coordenada Y do nó i
/i1 0
 i2 200
 i3 300
 i4 500
 i5 400
 i6 800
 i7 0
/;


parameter tal(i,j) (talij) tempo de viagem de nó i para o nó j;
*tal(i,j) = (60/100)*(((X_(i)-X_(j))**2 + (Y_(i)-Y_(j))**2)**(1/2));
tal(i,j) = (60/100)*(sqrt(sqr(X_(i)-X_(j)) + sqr(Y_(i)-Y_(j))));

parameter ct(i,j) (cij) custo de viagem de nó i para o nó j;
*ct(i,j) = (((X_(i)-X_(j))**2 + (Y_(i)-Y_(j))**2)**(1/2));
ct(i,j) = (sqrt(sqr(X_(i)-X_(j)) + sqr(Y_(i)-Y_(j))));

parameter fi(p) (fip) peso unitário do produto p;
fi(p) = 0.001*(sum(c, w(c)*l(c)*n(c,p)));

scalar teta capacidade do veículo;
teta = sum(p, sum(ii, d(p,ii)*fi(p)));

*janela de tempo do nó i1 até i6 no período t
parameter delta_inicial(t);
delta_inicial(t) = 480 + 1440*(ord(t) - 1);
parameter delta_final(t);
delta_final(t) = 1080 + 1440*(ord(t) - 1) ;

*janela de tempo do nó i7(depósito final) no período t
parameter delta_depot_inicial(t);
delta_depot_inicial(t) = 1440*(ord(t) - 1);
parameter delta_depot_final(t);
delta_depot_final(t) = 1440*ord(t) ;

scalar lambda Tempo de descarregar ou carregar por unidade de peso  / 0.02/;

scalar delta data de vencimento do cliente i / [1080 + 1440*(card(t) - 1)]/ ;

parameter s(ii) tempo de serviço do cliente i;
s(ii) = lambda*sum(p, fi(p)*d(p,ii));

parameter M_inicial(i,j) número muito grande inicial;
M_inicial(i,j) $(ord(i) eq 1 and ord(j) gt 1 and ord(j) lt card(j)) = (1080 + 1440*(card(t) - 1)) + min(lambda*teta, sum(ii $(ord(ii) gt 1 and ord(ii) lt card(ii)), s(ii))) + tal(i,j) ;

parameter M(i,j) número muito grande;
M(i,j) $(ord(i) gt 1 and ord(i) lt card(i) and ord(j) gt 1) = delta + s(i) + tal(i,j) ;

parameter Mc(c,t)  limite superior da quantidade de produção;
Mc(c,t) = min(K(t)/ro(c),sum(ii, sum(p, n(c,p)*d(p,ii))));

free variable z ;

*Lot-sizing variáveis    (MUDAR O NOME DAS VARIÁVEIS)
binary variable y(c,t) igual a 1 se tive produção do item c no período t caso contrário 0;
positive variable x(c,t) quantidade de produção do item c no período t;
positive variable Ic(c,t) inventário do item c no final do período t ;

*Routing variáveis
binary variable wo(i,j,r) igual a 1 se a rota r viajar diretamente do nó i para o nó j caso contrário 0  ;
positive variable Q(p,r,t) quantidade do produto p enviado na rota r no período t;
binary variable psi(i,r,t) igual a 1 se o nó i é visitado pela rota r no período t caso contrário 0;
positive variable mi(i,r) tempo inicial em que o nó i é abastecido pela rota r;

equations
fo equação 1
Saldo_Estoque equação 2
Saldo_Estoque_Balanco equação 3
Estoque_Minimo equação 4
Capacidade_Producao equação 5
Producao_item equação 6
Partindo_Deposito equação 7
Chegando_Deposito equação 8
Conservacao_Fluxo equação 9
Uma_Vez_Visitado equação 10
Rotas_Vazias_Ultima equação 11
Rota_Periodo equação 12
Produto_Rota equação 13
Visitar_Cliente equação 14
Rota_Vazia_Periodo_0 equação 15
Rota_Vazia_Periodo_1 equação 16
Janela_de_Tempo_A equação 17-A
Janela_de_Tempo_B equação 17-B
Primeiro_Cliente equação 18
Tempo_Descarregamento equação 19
Data_Vencimento equação 20
Sobreposicao_Rotas equação 21
Capacidade_Veiculo equação 22
*dompinio das variáveis
v1A  equação 23-A
v1B  equação 23-B
v2A  equação 24-A
v2B  equação 24-B
v3  equação 25
v4A  equação 26-A
v4B  equação 26-B
v5A  equação 27-A
v5B  equação 27-B
v6  equação 28
;

fo.. z =e= sum(c, sum(t, f(c)*y(c,t))) +  sum(c, sum(t, h(c)*Ic(c,t))) + sum(i $(ord(i)<card(i)), sum(j $(ord(i) gt 1), sum(r, ct(i,j)*wo(i,j,r))));
Saldo_Estoque(c,t-1).. Ic(c,t) + x(c,t) =e= sum(r, sum(p, n(c,p)*Q(p,r,t) + Ic(c,t)));
Saldo_Estoque_Balanco(c,t).. Ic(c,t-1) =g= sum(r, sum(p, n(c,p)*Q(p,r,t)));
Estoque_Minimo(c,t).. Ic(c,t) =g= Io(c);
Capacidade_Producao(t).. sum(c, ro(c)*x(c,t)) =l= K(t);
Producao_item(c,t).. x(c,t) =l= Mc(c,t)*y(c,t);
Partindo_Deposito(r,i) $(ord(i) eq 1).. sum(j $(ord(j) gt 1), wo(i,j,r))  =e= 1;
Chegando_Deposito(r,j) $(ord(j) eq card(j)).. sum(i $(ord(i) < card(j)), wo(i,j,r)) =e= 1;
Conservacao_Fluxo(r,i) $(ord(i) gt 1 and ord(i) lt card(i)).. sum(j $(ord(j) gt 1 and ord(j) <> ord(i)), wo(i,j,r)) =e= sum(j $(ord(j) lt card(j) and ord(j)<> ord(i)), wo(j,i,r));
Uma_Vez_Visitado(j) $(ord(j) gt 1 and ord(j) lt card(j)).. sum(i $(ord(i) lt card(i) and ord(i) <> ord(j)), sum(r, wo(j,i,r))) =e= 1 ;
Rotas_Vazias_Ultima(r) $(ord(r) < card(r)).. sum(i $(ord(i) gt 1 and ord(i) lt card(i)), wo(i,'i7',r)) =g= sum(i $(ord(i) gt 1 and ord(i) lt card(i)), wo('i1',i,r+1));
Rota_Periodo(p,r,t).. Q(p,r,t) =l= min(teta/fi(p),sum(ii $(ord(ii) gt 1 and ord(ii) lt card(ii)), d(p,ii))) ;
Produto_Rota(p,r).. sum(t, Q(p,r,t)) =e= sum((ii,i) $(ord(ii) gt 1 and ord(ii) lt card(ii)), d(p,ii)*sum(j $(ord(j) gt 1 and ord(j) <> ord(i)), wo(i,j,r)));
Visitar_Cliente(r,i) $(ord(i) gt 1 and ord(i) lt card(i)).. sum(t, psi(i,r,t)) =e= sum(j $(ord(j) gt 1 and ord(j) <> ord(i)), wo(i,j,r));
Rota_Vazia_Periodo_0(r).. sum(t, psi('i1',r,t)) =e= 1 - wo('i1','i7',r);
Rota_Vazia_Periodo_1(r).. sum(t, psi('i1',r,t)) =e= sum(t, psi('i7',r,t));
*rever essa parte
Janela_de_Tempo_A(i,t,r).. delta_inicial(t) - delta_inicial(t)*(1-psi(i,r,t)) =l= mi(i,r) ;
Janela_de_Tempo_B(i,t,r).. mi(i,r) =l= delta_final(t) + (delta-delta_final(t))*(1-psi(i,r,t))  ;
Primeiro_Cliente(j,r) $(ord(j) gt 1 and ord(j) lt card(j)).. mi(j,r) =g= mi('i1',r) + sum((ii,i) $(ord(ii) gt 1 and ord(ii) lt card(ii) and ord(i) gt 1 and ord(i) lt card(i)), s(ii)*sum(ki $(ord(ki) gt 1 and ord(ki)<>ord(i) and ord(ki)<>ord(ii)), wo(i,ki,r)+ tal('i1',j) - M_inicial(i,j)*(1 - wo('i1',j,r)))) ;
Tempo_Descarregamento(i,j,r,ii) $(ord(i) gt 1 and ord(i) lt card(i) and ord(j) gt 1 and ord(i)<>ord(j) and ord(i) gt 1 and ord(i) lt card(i) and ord(ii)<>ord(j)).. mi(j,r) =g= mi(i,r) + s(ii) + tal(i,j) + M(i,j)*(1 - wo(i,j,r));
Data_Vencimento(r,i) $(ord(i) gt 1 and ord(i) lt card(i)).. mi(i,r) =l= delta*sum(j $(ord(j) gt 1 and ord(j)<>ord(i)), wo(i,j,r));
Sobreposicao_Rotas(r) $(ord(r) lt card(r)).. mi('i1',r+1) =g= mi('i7',r);
Capacidade_Veiculo(r).. sum(p, fi(p)*sum((ii,i) $(ord(ii) gt 1 and ord(ii) lt card(ii) and ord(ii) gt 1 and ord(i) lt card(i)), d(p,ii)*sum(j $(ord(j) gt 1 and ord(j)<>ord(i)), wo(i,j,r)))) =l= teta;
v1A(c,t).. x(c,t) =g= 0  ;
v1B(c,t).. Ic(c,t) =g= 0 ;
v2A(c,t).. y(c,t) =g= 0 ;
v2B(c,t).. y(c,t) =l= 1 ;
v3(p,r,t).. Q(p,r,t) =g= 0;
v4A(i,r,t).. psi(i,r,t) =g= 0;
v4B(i,r,t).. psi(i,r,t) =l= 1;
v5A(i,j,r).. wo(i,j,r) =g= 0;
v5B(i,j,r).. wo(i,j,r) =l= 1;
v6(i,r).. mi(i,r) =g= 0;

model trab /all/;
solve trab using MIP minimizing z;

display w,c,h,f,ro,K,Io,X_,Y_,Mc;
display tal, ct, fi, teta, delta_inicial, delta_final, delta_depot_inicial, delta_depot_final, lambda, delta, R,s,M_inicial,M, Mc ;
display z.L;