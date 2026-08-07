/*session 1 : 결측치 처리 연습*/
libname shop '/home/student/shop_db';
PROC IMPORT DATAFILE="/home/student/shop_csv/users_dirty.csv"
	OUT = shop.users_dirty 	/*shop라이브러리에 users만들기 */
	DBMS=csv 			/*csv파일 불러오기*/
	REPLACE;			/*덮어쓰기 가능하도록 하기위해서 */
	GETNAMES=YES; 		/*첫 행 컬럼이름으로 */
	GUESSINGROWS=1000;  /*데이터 타입 1000개 행을 보고 타입예측*/
	DATAROW=2; 			/*첫째행은 컬럼명이라서 2번째부터 시작 */
RUN;

title '[s1.2] before - user_dirty 상태';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg

from shop.users_dirty;
quit;
title;

/*users_clean 데이터 셋으로 정제된 dataset 생성*/
data shop.users_clean;
	set shop.users_dirty;
	length age_grp $6 email_status $10;
	if missing(age) then age=0;
	if missing(city) then city ='미상';

if age =999 or age<0 then delete;
age_grp=floor(age/10)*10;
format signup_date datetime16.;
run;

/*before - 정제전 데이터 확인 */
proc freq data=shop.users_dirty;
	tables age city /nocum missing;
run;

/*after - 정제전 데이터 확인 */
proc freq data=shop.users_clean;
	tables age city /nocum missing;
run;

title '[s1.2] after - user_clean 상태';
proc sql;
	select count(*) as n_total,
	sum(missing(email)) as n_email_null,
sum(missing(age)) as n_age_null,
sum(missing(city)) as n_city_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg

from shop.users_clean;
quit;
title;

data work.users_chk;
	set shop.users_dirty;
if missing(age) then age_missing=1;
	else 			age_missing=0;

nmiss_cnt =nmiss(age, total_spent);

cmiss_cnt =cmiss(age,email,city);

if not missing(age) and age>0
then	age_valid=1;
run;

proc print data=work.users_chk(obs=10);
	var age total_spent nmiss_cnt cmiss_cnt age_valid
;run;



/* 1)결측을 진단 */
Title "[S2.2] 결측 진단 - users_dirty";
/*age의 평균으로 결측값 대체*/
proc  sql noprint;
	select mean(age), median(age) into :age_mean, : age_med
	from shop.users_dirty
	where age between 1 and 99;
Run;
%put 정상 평균 = &age_mean	중앙값 = &age_med;

/* age가 결측이면 중앙값으로 대체-> 결과 확인 user2 */
DATA user2;
	set shop.users_dirty;
	if age =  . Then age =&age_med;
Run;
Proc print DATA=users2(obs=5);
	var age;

RUN;
Proc print DATA=shop.users_dirty

/**/

title '[s1.2] before - user_dirty 상태';
proc sql;
	select count(*)
	sum(missing(email)) as n_email_null,

sum(missing(city)) as n_city_null,
sum(missing(age)) as n_age_null,
sum(missing(age=999)) as n_age_999,
sum(missing(age<0)) as n_age_neg
from user3;
quit;
title;

/*coalescec() 함수로 결측값 처리-> email 보정 */
%let personal_email = "abcd@naver.com";

DATA work.user4;
	SET shop.users_dirty;
/*email 없으면 user_name@noemail.local */
	email_fix = COALESCEc(email, &personal_email, 'unknown@unknown');
	keep user_id user_name email email_fix;

Run;

proc print data=user4(obs=5);
where MISSING(EMAIL);
RUN;
age_safe = COALESCE(age, &age_mean, 0);
RUN;
/*
 1) 숫자 - COALESCE 
age = COALESCE(age, 0);
total_spent = COALESCE(total_spent, 0);
/* 2) 문자 - COALESCEC 
city = COALESCEC(city, "미상");
email = COALESCEC(email, "no-email");
/* 3) 우선순위 처리 
LENGTH best_email $50;
best_email = COALESCEC(work_email,
personal_email,
"no-contact");
*/

/*결측행 제거*/

DATA user5;
		SET shop.users_dirty;
		if missing(age) OR missing(city) then delete;
run;

proc sql;
		select count(*) as users_dirty_rows from shop.users_dirty;
		select count(*) as user5_rows from shop.user5;
quit;


/*session 3 실습*/
/*(중략)*/
dATA work.users_no_outlier;
	set shop.users_dirty
	IF age > &hi THEN delete;
	if age < &lo then delete;	/*음수 제거*/
Run;

/* orders_dirty 데이터셋에서  이상치 제거 irq 기준  하한과 상한을 검색한 뒤
화면에 출력, orders_dirty에 적용한 뒤 orders_clean 생성
total_amount */
PROC MEANS DATA=SHOP.orders_dirty;
	where total_amount > 0;
	var total_amount;
	output out = orders_status
			min=t_min
			max=t_max
			p25=t_q1
			p75=t_q3;
run;

/* 1. proc summary로 통계량(min, max, q1, q3) 집계 */
proc summary data=shop.users_dirty;
		where age > 0;
		 var age;
		output out = notanywords
;

/* 1. 1%와 99% 백분위수  계산 후 테이블로 저장 */
proc means data = shop.users_dirty;
	where age > 0;
proc sql noprint;
/*SCAN - N번째 단어*/

DATA work.users_scan;
SET mylib.users;
LENGTH email_id $30 email_dom $30
city_main $10 city_dist $20;
/* 1) 이메일 - 아이디 / 도메인 */
email_id = SCAN(email, 1, "@");
email_dom = SCAN(email, 2, "@");
/* "u01@naver.com" → "u01" / "naver.com" */
/* 2) 도메인의 회사 (앞 부분) */
email_co = SCAN(email_dom, 1, ".");
/* "naver.com" → "naver" */
/* 3) 주소 분할 */
city_main = SCAN(city, 1, " ");
city_dist = SCAN(city, 2, " ");
/* "서울 강남구" → "서울" / "강남구" */
RUN;
/* 4) 도메인별 카운트 */
PROC FREQ DATA=work.users_scan order=freq;
	TABLES email_dom / NOCUM ORDER=FREQ;
RUN;
/* 시도별 카운트 */
proc freq Data=work.users_scan Order=freq;
	tables city_main /Nocom;
Run;
/*(중략)*/
title "[S4.6-1] step 1 - 저제 전 channel , email 유형";

Proc print data=users-date(obs=10);
	var signup_date signup_d signup_dt d1 d2;
RUN;

/* put - 날짜 (num) -> 문자 */
Data work.users_put;
	set users_date;

	/* 1) 월별 키 */
	month_key = put(signup_d, YYYYMMG.);
	/* ->"202501"*/

/*DAtepart, timepart, dhms*/
DATA work.users_d;
SET mylib.users;
/* 1) DATETIME → DATE */
signup_d = DATEPART(signup_at);
FORMAT signup_d YYMMDD10.;
/* 2) 시간만 */
signup_t = TIMEPART(signup_at);
FORMAT signup_t TIME8.;
/* 3) 연·월·일·요일 */
signup_year = YEAR(signup_d);
signup_month = MONTH(signup_d);
signup_day = DAY(signup_d);
signup_wkday = WEEKDAY(signup_d);
signup_qtr = QTR(signup_d);
/* 4) DATE → DATETIME */
d_only = INPUT("2025-01-01", YYMMDD10.);
dt_new = DHMS(d_only, 10, 30, 0);
FORMAT dt_new DATETIME16.;
RUN;

proc print data=users_D(obs=10);
	var signup_date signup_d signup_t signup_year signup_month signup_Day
		signup-wkday signup_d