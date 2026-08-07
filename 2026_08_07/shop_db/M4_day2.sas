%let userid = student;						/*본인 OnDemand USERID*/
%let csv_dir = /home/$userid/shop_csv;		/* setup_data.py 출력 폴더 */
libname shop = "/home/$userid/shop_db;

proc import
	datafile = "CSV_dir/orders_dirty.csv"
	out	   	 = "shop.orders_dirty
	DBMS	 = csv
	Replace;
	getnames		= Yes; /* 첫 행을 컬럼명으로 */
	guessingrows	= max; /* 모든 행 검사 -> 타입 정확 (★ 권장) */
	RUN;

/* 컬럼의 데이터 타입 확인 */
TITLE "컬럼 정보 확인 "
Proc contents DATA=shop.orders_dirty;
run;

title "처음 10행 데이터 보기";
PROC PRINT DATA = shop.orders_dirty(obs=10);
run;
TITLE "적제된 데이터 개수 확인" ;


/* sashelp 에 있는  car의 정보 확인 */
proc print data=sashelp.cars (obs=10);
Run;

proc contents data =sashelp.cars;
Run;

proc sql;
	select count(*) from sashelp.cars;
quit;

/* shop.users tax 컬럼을 추가 tax = total_spent * 0.1로 저장 후
	work.temp
	work.temp -> channel별로 누적매출을 출력한 뒤
	shop.user_tax 로 저장 */


/* session 3 proc means */
/*users_dirty의 age 컬럼에 대한 통계정보 확인*/

PROC MEANS DATA=shop.users_dirty maxdec=1;
	var age;
RUN;

PROC MEANS DATA=shop.users_dirty N means median Q1 Q3 maxdec=1;
	var age;
RUN;

PROC MEANS DATA=shop.users_dirty min max var range maxdec=1;
	var age;
Run;

PROC means data=shop.users_dirty N NMISS;
	VAR AGE
RUN;


/* 그룹별 데이터 평균을 구하려고 한다. */
proc means data=shop.users_dirty N means SUM	maxdec = 1;
	var = age;
	class channel GENDER;
	RuN;

proc means data=shop.users_dirty N means SUM	maxdec = 1;
	VAR age;
	class channel signup_device gender;
 	/* type channnel * gender; */
RUN;



output out 

proc means 