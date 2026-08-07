libname shop '/home/student/shop_db';
	%let userid = &sysuserid;
	%LET root = /HOME&USERID;

	%PUT &USERID &root;
	%let DB = shop_db;
	%put &userid &root &DB &Root/&DB;
	libname shop "&root/&DB";

/* [목표] %let으로 YYYYMM + CUTOFF 정의 후 TITLE/WHERE/FILE 에 적용
	[산출물] 월별 매출 top N 보고서 (자동 파일명)
*/
	%let yyyymm = 202611;
	%let cutoff = 100000;
	&let report_dir = &root.reports;

	OBS pdf file="&report_dir/&yyyymm._매출.pdf";
	title "&yyyymm 월간 매출 (cutoff=&cutoff)";

data month;
	set shop.orders;
	where put(order_date, YYMMN6.) = "&yyyymm"
	 and total_amount >= &cutoff;
RUN;
Proc print Data=month(obs=20) noobs;
run;

title;
ODS PDF CLOSE;

/* ── S1.3  시스템 매크로 변수 — &SYSDATE · &SYSTIME ──── */
%PUT SYSDATE  = &SYSDATE   (오늘 날짜);
%PUT SYSTIME  = &SYSTIME   (현재 시간);
%PUT SYSDAY   = &SYSDAY    (요일);
%PUT SYSUSERID = &SYSUSERID (본인 ID);

TITLE "[S1.3] 시스템 매크로 변수 — &SYSDATE &SYSDAY 보고서";
PROC PRINT DATA=shop.users (OBS=5) NOOBS;
   VAR user_id name age channel;
RUN;
TITLE;

/* macro 변수 응용  */
%LET TARGET  = paid;
%LET MIN_AMT = 50000;
/*&min_amt: 50000 이상인 값만 불러온다.*/
%LET TOP_N   = 10;

%PUT TARGET  = &TARGET;
%PUT MIN_AMT = &MIN_AMT;
%PUT TOP_N   = &TOP_N;

TITLE "[S1.2] LET 사용 — &TARGET 주문 &MIN_AMT+ TOP &TOP_N";
proc sql outobs=&top_n;
	select order_id, user_id, total_amount, channel
	from shop.orders
	where status = "&target"
	and total_amount >= &min_amt
	order by total_amount desc;
quit;
title;


/* session 2: %macro %mend*/
%macro vip_report(grade=);
		Proc print data =shop.users (obs = 10);
		where vip_grade="&grade"; var user_id name total_spent vip_grade;
run;
%mend;
%vip_report(grade=gold);
%vip_report(grade=silver);

%macro ch_KPI(ch=);
	title "&ch 채널 KPI";
	proc sql;
		select "ch" as channel length=15.
		count(*) as 주문건수,
		sum(total_amount) as 주문총금액 format comma15.
	from shop.orders
	where status = 'paid'
/* 호출 -> channel : organic, email */
%ch_kpi(ch=organic);
%ch_kpi(ch=email);

%Macro ch_age_kpi(ch=organic, lo=20, hi=60, top=10);
	title "&ch (%lo~&hi 세)  top &top";
Proc sql outobs=&top;
	select u.user_id, u.name, u.age, o.total_amount
	`from shop.users u inner join shop.orders o on u.user_id = o.user_id
	where u.age between &lo and &hi
	and o.channel = "&ch"
	and o.status = 'paid'
	order by o.total_amount desc;
	quit;
	title;
%mend;

OPtion mprint mlogic symbolgen;/* 디버깅 시작 */
%ch_age_kpi();
%ch_age_kpi(ch=social);
%ch_age_kpi(ch=social, lo=20, hi=29, top=20);

OPtion nomprint nomlogic nosymbolgen;
/*디버깅 종료*/

/* vip 등급별로 macro 만들기- KPI 집계 -> vip_kpi(grade=)
	grade, 건수, 평균주문액(ltv를 쓸 거니 total_spent로 하자 ), 평균주문건수(order_count)
	format 8.1 
보고서 타이틀은 -> gold 등급 통계 */
%MACRO vip_kpi(grade=);

    TITLE "&grade 등급 통계";

    PROC SQL;
        SELECT
            "&grade" AS vip_grade LENGTH=10,
            COUNT(*) AS n_users,
            AVG(total_spent)
                AS avg_spent FORMAT=COMMA12.,
            AVG(order_count)
                AS avg_orders FORMAT=8.1
        FROM shop.users
        WHERE vip_grade = "&grade";
    QUIT;

    TITLE;

%MEND vip_kpi;
%vip_kpi(grade=silver);	

/*session 3 : %DO %IF*/
%MACRO yearly_pdf(year=);
%DO m = 1 %TO 12;
%LET m2 = %SYSFUNC(
PUTN(&m, z2.));
%LET ym = &year.&m2;
ODS PDF FILE="&REPORT_DIR/%YM.매출.pdf";
PROC PRINT DATA=shop.orders;
WHERE PUT(order_date,YYMMN6.)
= "&ym";
RUN;
ODS PDF CLOSE;
%END;
%MEND;
%yearly_pdf(year=2024)

/* %DO~%END 연습 */
%let channels = organic paid_search social referral email other;

%macro loop_channels;
		%DO;
/*USERS에서 검색해서 channels를 생성해보자*/
Proc sql;
	select distinct channel into:channels seperated by " "
	from=shop.users;
quit;

%put channels : &channels;

%macro loop_channels;
	%DO i = %to 6;
		%let ch = %scann(&channels,&i);
		%put [&i] &ch;
		%ch_kpi(ch=&ch)	
	%end;
%mend loop_channels;

%loop_channels;

/* ----S3.2 %IF - */


%MACRO COUNTDOWN;
		%LET N = 5;
		%DO %UNTIL (&N =0);
		%PUT 카운트 &n
		%let n = %eval


/* session 4 into 변수 */
/* - $4.1 into : 변수 seperated by - 여러 값 ---------------*/

proc sql;


/*완전 자동화 매크로 작성 - 체널 자동 반복 */
/* channel을 검색해서 변수(리스트)에 저장*/
proc sql noprint;
	select distinct channel into: ch_list seperated by ""
	from shop.users;
quit;

%put ch_list -> &ch_list */체널 목록*/
%macro auto_all_channels;
		%local n_ch i ch;
		%Let N_ch = %sysfunc(counttw(&ch_list));
		/* 자동 계산된 n_ch 수만큼 반복 루프 생성*/
		%DO i = 1 %TO %n_ch;
			%let ch = %scan(&ch_list, &i);
			%put [동적  [동적 [&i /&n_ch]]  &ch;
			%ch_kpi(ch=&ch);
			%end
		%mend;
		%auto_channels;


/* vip list [산출물] &vip_list + 동적 분석 결과*/
Proc sql noprint;
	select user_id into :vip_list seperated by ''
	from shop.users
	where vip_grade = 'gold'
quit;

%put &vip_list;
%put ;

proc sql noprint;
	

/* session 6 excel */
/* 실습 1
%let yyyymm + cutoff 정의 후 자동 파일명 + 동적 where -> yyyymm 매크로 -> YYYYMM_매출.pdf*/

/* 실습 2
%macro 5 csv 적재 : import_csv(name=) 매크로 정의 + 4회 호출
- campaigns.csv categories.csv coupon.csv events.csv*/

/* 실습 3
%DO 1 % TO 12 동적 파일명 + ods pdf 12회 반복
device별 주문건수, 주문총액 -> 정상 거래만 (paid)
산출물 -> 202401_매출.pdf ~ 202412_매출_pdf*/

*/ 실습 4
channel 별 고객 리스트 작성 후
channel 별 데이터셋 생성 -> user_id, name. 가입일자, 주문건수, 주문금액*/