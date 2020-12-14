sets j item /j1*j4/
     t per�odo /t1*t5/;
;

parameter C(t) capacidade do per�odo (horas);
C(t) = 70;

parameter p(j) tempo de produ��o (horas) do item j;
p(j) = 1;

parameter h(j) custo de estocagem do item j
/j1 25
 j2 10
 j3 25
 j4 10/;

parameter s(j) custo setup da m�quina para o item j
/j1 900
 j2 850
 j3 900
 j4 850/;

table d(j,t)
   t1  t2  t3  t4  t5
j1 10  0   20  30  10
j2 20  0   15  30  10
j3 0   10  0   5   30
j4 10  0   30  0   10;

Free variable Z;
positive variable q(j,t) quantidade do item j produzido no per�odo t;
positive variable I(j,t) estoque do item j no per�odo t;
binary variable X(j,t) indica o setup para o item j no per�odo t;

equations
fo
eq2
eq3
eq4
;

fo.. Z =e= sum((j,t), s(j)*x(j,t)) + sum((j,t), h(j)*I(j,t));
*balan�o de estoques
eq2(j,t).. I(j,t) =e= I(j,t-1) + q(j,t) - d(j,t);
*capacidade de produ��o de cada item j no per�odo t
eq3(j,t).. p(j)* q(j,t) =l= C(t) * X(j,t);
*capacidade de produ��i de todos os itens j no per�odo t
eq4(t).. sum(j, p(j)*q(j,t)) =l= C(t);

model CLS /all/;
solve CLS using MIP minimizing Z;
display Z.L, q.L, x.L, I.L;