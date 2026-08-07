%LET USERID  = student;                         /* ← 본인 OnDemand USERID */
%LET CSV_DIR = /home/&USERID/shop_csv;          /* setup_data.py 출력 폴더 */
LIBNAME shop "/home/&USERID/shop_db";

PROC IMPORT
   DATAFILE = "&CSV_DIR/orders_dirty.csv"
   OUT      = shop.orders_dirty
   DBMS     = CSV
   REPLACE;
   GETNAMES     = YES;           /* 첫 행을 컬럼명으로 */
   GUESSINGROWS = MAX;           /* 모든 행 검사 → 타입 정확 (★ 권장) */
RUN;

/* 컬럼의 데이터 타입 확인 */
TITLE "컬럼 정보 확인 ";
PROC CONTENTS DATA=shop.orders_dirty;
run;

TITLE "처음 10행 데이터 보기 ";
PROC PRINT DATA=shop.orders_dirty(obs=10);
run;
TITLE "적제된 데이터 갯수 확인 ";
PROC SQL;
	select count(*) from shop.orders_dirty;
QUIT;
TITLE;

/* sashelp 에 있는 car 의 정보 확인 */
PROC PRINT data=sashelp.cars(obs=10);
RUN;

PROC CONTENTS data=sashelp.cars;
RUN;

PROC sql;
	select count(*) from sashelp.cars;
quit;

/* shop.users tax 컬럼을 추가 tax = total_spent * 0.1로 저장 후 
	work.temp 
	work.temp -> channel 별로 누적매출을 출력한 뒤 
	shop.user_tax 로 저장 */

/* 1단계 temp 작성 */
DATA temp;
	SET shop.users;
	tax = total_spent * 0.1;
RUN;

PROC CONTENTS DATA=temp;   /* 컬럼 정보 확인 */
RUN;

/* channel을 기준으로 sort */
PROC SORT DATA=temp;
	by channel;
RUN;

PROC PRINT DATA=temp(OBS=10) NOOBS;
RUN;

DATA shop.users_tax;
	set temp;
	RETAIN 누적합꼐 0;
	IF FIRST.channel THEN 누적합계 = 0;
	누적합계 + total_spent;
RUN;
PROC CONTENTS DATA=shop.users_tax;   /* 컬럼 정보 확인 */
RUN;
PROC PRINT DATA=shop.users_tax(OBS=10) NOOBS;
RUN;
PROC SQL;
	SELECT count(*) FROM shop.users_tax;
RUN;

PROC FREQ DATA=shop.users_tax;
	TABLES channel / NOCUM ;
RUN;

/* session 3 proc means */
/* users_dirty 의 age 컬럼에 대한 통계정보 확인 */
PROC MEANS DATA=shop.users_dirty MAXDEC=1;
	VAR age;
RUN;

PROC MEANS DATA=shop.users_dirty N MEAN MEDIAN STD Q1 Q3 MAXDEC=1;
	VAR age;
RUN;

PROC MEANS DATA=shop.users_dirty SUM SKEWNESS P95 MAXDEC=1;
	VAR age;
RUN;

PROC MEANS DATA=shop.users_dirty MIN MAX VAR RANGE MAXDEC=1;
	VAR age;
RUN;

PROC MEANS DATA=shop.users_dirty MEAN MEDIAN MODE MAXDEC=1;
	VAR age;
RUN;

PROC MEANS DATA=shop.users_dirty N NMISS;
	VAR age;
RUN;

/* 그룹별 평균, channel 로 */
PROC MEANS DATA=shop.users_dirty N MEAN SUM  MAXDEC=1;
	VAR age;
	CLASS channel;
RUN;

/* 체널별 성별 교차 */
PROC MEANS DATA=shop.users_dirty N MEAN STD  MAXDEC=1;
	VAR age;
	CLASS channel gender;
RUN;

PROC MEANS DATA=shop.users N MEAN STD  MAXDEC=1;
	VAR age;
	CLASS channel signup_device gender;
/* 	TYPES channel * gender; */
RUN;

/*  output out=정장하고자 하는 파일명 */
PROC MEANS DATA=shop.users_dirty NOPRINT;
	VAR age;
	CLASS channel;
	OUTPUT OUT=ch_stats
		N=cnt mean=age_mean std=age_std;
RUN;

/* 작성된 데이터 출력 */
PROC PRINT DATA=ch_stats NOOBS;
	WHERE _TYPE_ = 1;
	VAR channel cnt age_mean age_std;
	FORMAT age_mean age_std 8.1;
RUN;

/* 그래프로 데이터 확인 */
PROC SGPLOT DATA=ch_stats;
	WHERE _TYPE_ = 1;
	VBAR channel / RESPONSE=age_mean;
RUN;

PROC SGPLOT DATA=ch_stats;
	WHERE _TYPE_ = 1;
	VBAR channel / RESPONSE=age_mean;
	xaxiS label ="가입체널";
	Yaxis LABEL = '평균매출';
RUN;

/*
제미나이한테 샘플 코딩 해달라고 하자*/

/*
session  4*/

Proc freq data=shop.users_dirty;
	tables channel * gender /norow nocol no percent

PROC FREQ DATA=SHOP.orders;

/*session 5 : univeriate 정규분포 확인 */
Proc univerate Data=shop.orders NORMAL;
	VAR total_amount;
	HISTOGRAM TOTAL_amount / normal;
	QQPLOT total_amount / normal(MU=EST SIGMA = EST)

/* 1) 오름차순 */
PROC SORT DATA=mylib.users OUT=u1;
BY user_id;
RUN;
/* 2) 내림차순 */
PROC SORT DATA=mylib.users OUT=u2;
BY DESCENDING age;
RUN;
/* 3) 복합 키 */
PROC SORT DATA=mylib.users OUT=u3;
BY channel age;
RUN;
/* 4) 혼합 (채널 오름, 나이 내림) */
PROC SORT DATA=mylib.users OUT=u4;
BY channel DESCENDING age;
RUN;
/* 5) 다중 키 NODUPKEY */
PROC SORT DATA=mylib.users OUT=u5 NODUPKEY;
BY user_id signup_at;
RUN;