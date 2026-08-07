libname shop '/home/student/shop_db';

/* CAS 세션 시작 */
CAS mySession;
/* caslib 활성 */
CASLIB _ALL_ ASSIGN;/*위쪽 라이브러러리에 assign 해라*/
/* dataset → CAS table 적재 */
PROC CASUTIL;
	load data = shop.users
		outcaslib="CASUSER"
		CASOUT="USERS"
promote;
QUIT;

PROC MEANS DATA = SHOP.USERS;
	VAR AGE;
RUN;

PROC MEANS DATA = casuser.users;
	var age;
run;
/*
LOAD CASDATA="users.sashdat"
INCASLIB="casuser"
OUTCASLIB="casuser"
CASOUT="users_cas";
QUIT;
*/
/* CAS table 에서 분석 - 빠름 */
PROC MEANS DATA=casuser.users_cas;
VAR age;
RUN;
/* 세션 종료 */
/*CAS mySession TERMINATE;*/
/* CAS library의 파일과 테이블 정보 확인*/
PROC  CASUTIL;
	LIST FILES INCASLIB="CASUSER";
	LIST TABLES   IN CASLIB="CASUSER";
QUIT;

/* CAS TABLE 메모리 -> 디스크 영구 저장*/
PROC CASUTIL;
   LIST TABLES INCASLIB="casuser";
/*	list tables incaslib="casuser";*/
quit;


proc casutil;
	save casdata="users"
	INCASLIB="casuser"
	outcaslib="casuser"
	casout="users_backup.sashdat"
	replace;
quit;


/*저장된 디스크에서 영구 삭제*/
/*
Proc casutil;
	deletesource casdata="users_backup.sasdat"
				Incaslib="casuser"
quit;

*/
CAS MYSESSION TERMINATE;
CAS MYSESSION;
CASLIB _ALL_ ASSIGN;
 	libname mycas cas caslib="casuser";

libname shop "/home/student/shop_db";
LIBNAME MYCAS CAS CASLIB="CASUSER";

DATA SHOP.USERS_CAS1;
	SET MYCAS.USERS;
RUN;

/*
proc casutil
	save casdata+"users"
	incaslib= "casuser"
	outlib="SHOP"
	OUT="USERS_CAS1"
	
QUIT;
TITLE;
*/


proc casutil;
	LIST files incaslib="casuser"
		/*list tables*/

/*session2  기존의 proc 호환이 되는지 확인 */

/* ── S2.4  ★ 미니 실습 2 - Viya 환경 진단 + D1~D5 호환 검증 (10분) ──
   목표 : Viya 환경 정보 + SAS 클래식 코드 (D1~D5) Viya 실행 확인
   ──────────────────────────────────────────────────────────────────── */

/* (1) Viya 환경 정보 (시스템 매크로 변수) */
%PUT [Viya 환경 정보];
%PUT   SYSUSERID = &SYSUSERID;
%PUT   SYSDATE   = &SYSDATE;
%PUT   SYSDAY    = &SYSDAY;
%PUT   SYSVER    = &SYSVER     (SAS 버전);

/* (2) D1 코드 검증 - DATA STEP + PROC PRINT */
TITLE "[S2.4-1] D1 코드 - DATA STEP + PROC PRINT (Viya 호환 검증)";
DATA work.viya_test;
   SET shop.users (OBS=10);
   age_group = IFC(age < 30, '청년', '중장년');
RUN;
PROC PRINT DATA=work.viya_test NOOBS;
   VAR user_id name age age_group channel;
RUN;
TITLE;

/* (3) D2 코드 검증 - PROC MEANS + FREQ */
TITLE "[S2.4-2] D2 코드 - PROC MEANS + FREQ (Viya 호환 검증)";
PROC MEANS DATA=shop.users N MEAN STD MAXDEC=1;
   CLASS channel;
   VAR total_spent;
RUN;
PROC FREQ DATA=shop.users;
   TABLES vip_grade / NOCUM NOPERCENT;
RUN;
TITLE;

/* (4) D3 코드 검증 - PROC SQL */
TITLE "[S2.4-3] D3 코드 - PROC SQL JOIN (Viya 호환 검증)";
PROC SQL OUTOBS=5;
   SELECT u.user_id, u.name, COUNT(o.order_id) AS 주문수
   FROM shop.users AS u
   LEFT JOIN shop.orders AS o ON u.user_id = o.user_id
   GROUP BY u.user_id, u.name
   ORDER BY 주문수 DESC;
QUIT;
TITLE;


cas mysession terminate;
 /* cas 엔진 start*/
cas session1;
/* cas library 할당*/
caslib_all_assign;
/* caslib 목록*/

proc cas;
	table.caslibinfo;
run;

/* casutil -> 테이블 목록 확인*/
PROC CASUTIL;
	list tables incaslib="casuser";
run;

/* shop.orders load 후 global로 변경*/
data casuser.orders;
	set shop.orders;
run;

proc casutil;
	promote casdata="orders"
	incaslib="casuser"
	outcaslib="casuser";

run;
cas session1 terminate;
cas session2;
caslib
caslib _all_ assign;

/**/
proc casutil;
	copy casdata="orders"
	incaslib="casuser"
	outcaslib="casuser"
	casout="orders_copy";

quit;
/* 기존의 테이블 메모리에서 삭제 */
proc casutil;
	droptable casdata="orders"
			incalib="casuser";
run;

/* 3.복사한 테이블명을 원래의 테이블로 rename*/

proc casutil;
	altertable casdata="orders_copy"
			incaslib="casuser"
			rename="orders";

quit;
cas session 2 terminate;

cas mysession;
caslib_all_assign;

/* session 4 :cas로 load*/
/* proc import : csv -> cas */
proc import;
 	datafile="/home/student/shop_csv/order_items.csv";
	out=casuser.order_item
	dbms = csv replace;
	getnames = yes;
	guessingrows=max;
run;

proc import
	datafile = "/home/student/shop_csv/order_items.csv"
	out = casuser.order_items
	dbms = csv replace;
	getnames =yes;
	guessingrows=max;

Run;
Proc print data=casuser.order_items(obs=10);
run;

/* 1. order_itmes -> save로 order_items_bak */
/* 2. order_items -> order_item-restore로 load*/
/* 3. order_itemsbak와_ order_item_restore 를 삭제 */
Proc casutil;
		drop table

/* casuser 의 CAS 테이블 목록 */
proc casutil;
	list files Incaslib="casuser";
	list tables incaslib="casuser";
quit;

/* 자신만의 caslib 생성 */
caslib myown
	datafile myown
		datasource=(srctype = "path")
		path = "/home/student/casdata";
		sessref = mysession;

caslib _all_ assign;
/* save 영구 -> 폴더에 write 권한 부여 후 실행 */
data myown.users;
	set casuser.users
run;
/* caslib 해제 */
caslib myown drop;

/* session 5 :proc cas -> sas viya 엔진에서 실행*/

	cas mysession;
	caslib _all_ assign;


/* simple.summary -> proc means */
libname shop "home/student/shop_db";

proc means data=shop.users;
 var age;
run;

proc sas;
	simple.summary /
	table = "users" , inputs="age";
quit;


/* simple, freq - Proc freq*/
proc cas;
	simple.freq /table ="users", inputs="channel";
quit;


/* simple.crosstab :2차원 교차*/
proc cas;
	simple.crosstab /
	table "users",
	row = "channel",
	col = "gender";
quit;

Proc cas;
	simple.crosstab /
cas mysssion terminate;
cas mysession;

caslib _all_ assign;
data casuser.orders;
	set shop.orders;
run;

/* join - CAS table끼리 결합 */
proc  sql;
	select * from casuser;

Data casuser.orders;
	
/* 고객 등급별 평균 구매금액 -> vip_grade, total_spent => proc sql, proc cas*/
/* proc sql*/
proc sql;
	select vip_grade as 등급, avg(total_spent) as 평균구매금액
	from casuser.users
	group by vip_grade;
quit;

proc cas;