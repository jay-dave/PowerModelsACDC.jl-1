mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin  syncarea
mpc.bus = [
1       3       0	0	0   0   1       1.06	0	345     1       1.1     0.9     1;
2       2       0	0	0   0   1       1       0	345     1       1.1     0.9   	1;
3       2       23000	0	0   0   1       1       0	345     1       1.1     0.9  2;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
1   2   0.02    0.06    0.06    100   100   100     0       0       0 -60 60;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
1	0       0	2400      -2400    1.06	100       1       2400     0 0 0 0 0 0 0 0 0 0 0 0;
2 	0       0	2400      -2400    1.06	100       1       2400     0 0 0 0 0 0 0 0 0 0 0 0;
3 	0       0	23000      -23000    1.06	100       1       23000     0 0 0 0 0 0 0 0 0 0 0 0;
];

%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=1;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
1           1       0       1       320         1.1     0.9     0;
2           1       0       1       320         1.1     0.9     0;
3           1       0       1       320         1.1     0.9     0;
4           1       0       1       320         1.1     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g islcc  Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin syncarea
mpc.convdc = [
1               1   2       1      2400     200    0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     158    1.0079   0 2400 -2400 2400 -2400  1;
2               2   1       1      -2400    -200   0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     -158   1.0079   0 2400 -2400 2400 -2400  1;
3               3   1       1      2400     200    0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     158    1.0079   0 2400 -2400 2400 -2400  2;
4               3   1       1      -2400    -200   0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9    	36  1       0.5515 0.887  2.885    4.371      0.0050     -158   1.0079   0 2400 -2400 2400 -2400  2;
%		1               1   2       1      2400     200    0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     158    1.0079   0 2400 -2400 2400 -2400  1;
%		2               2   1       1      -2400    -200   0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     -158   1.0079   0 2400 -2400 2400 -2400  1;
%		3               3   1       1      2400     200    0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9     36  1       0.5515 0.887  2.885    4.371      0.0050     158    1.0079   0 2400 -2400 2400 -2400  2;
%		4               3   1       1      -2400    -200   0           1     0  0.007    0        1 0    0  0.0001   0.007        0  320         1.1     0.9    	36  1       0.5515 0.887  2.885    4.371      0.0050     -158   1.0079   0 2400 -2400 2400 -2400  2;
];

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status fail_prob
mpc.branchdc = [
%	1       2       0.55   0  0    2400     2400     2400     1		  0.0115;  %cable=225 100km
	1       4       1.65   0  0    2400     2400     2400     1		  0.0345; %cable=675 300km
	2       4       0.825  0  0    2400    2400      2400     1	  	0.0172; %cable=337.5 150km
%	2       3       1.65   0  0    2400     2400     2400     1	  	0.0345; %cable=675 300km
	1       3       0.55   0  0    2400     2400     2400     1	  	0.0115;  %cable=225 100km
	3       4       1.925  0  0    2400    2400      2400     1	  	0.0402; %cable=787 350km

%	1       2       0.11   0  0    2400     2400     2400    1		  0.0115;  %cable=225 100km
%	1       4       3.3   0  0    2400     2400     2400     1		  0.0345; %cable=675 300km
%	2       4       1.65  0  0    2400    2400      2400     1	 	  0.0172; %cable=337.5 150km
%	2       3       3.3   0  0    2400     2400     2400     1	  	0.0345; %cable=675 300km
%	1       3       1.1   0  0    2400     2400     2400     1	  	0.0115;  %cable=225 100km
%	3       4       3.85  0  0    2400    2400      2400     1	  	0.0402; %cable=787 350km
 ];

 %% generator cost data
 %	1	startup	shutdown	n	x1	y1	...	xn	yn
 %	2	startup	shutdown	n	c(n-1)	...	c0
 mpc.gencost = [
 	2	0	0	3		0.00000001  0	0;
 	2	0	0	3 	0.00000001	0	0;
 	2	0	0	3 	0.00000001	10	0;
 ];

 %% reserve data
 %pu value of percentage of total load
 %column_names%  syncarea Pgmax Tg Pfmax Tf Td Tcl H Cf Cg
 mpc.reserves = [
	1	48  5  48   1   0.05   0.150  4 80 5.3; % reserves are in MW*100 i.e. 24 = 2400MW
	2	48  5  48   1  0.05   0.150  4 80 5.3;
 ];
 %the syn. area no. must start from 1 to length of reserves
