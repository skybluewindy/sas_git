libname shop "/home/student/shop_db";


PROC SQL OUTOBS=10;
   SELECT name, channel,
          CASE channel
             WHEN 'paid_search' THEN '검색 광고'
             WHEN 'social' THEN '소셜'
             WHEN 'organic' THEN '오가닉'
             WHEN 'referral' THEN '추천'
             ELSE '기타'
          END AS 채널_한글
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, vip_grade,
          CASE
             WHEN vip_grade IS NULL THEN '미입력'
             WHEN vip_grade = 'gold' THEN 'VIP'
             ELSE '일반'
          END AS 분류
   FROM shop.users;
QUIT;

/*연령대별 회원수를 출력 <30 -> 20대, <40->30대, <50 ->40대, <60->50대, '50대+ 회원수' */
PROC SQL OUTOBS=10;
	select case
		when age < 30 then '20대'
		when age < 40 then '20대'
		when age < 50 then '20대'
		when age < 60 then '20대'
	else '50대 +'
	end as 연령대, count(user_id) as 회원수
	from shop.users
	group by calculated 연령대;
quit;
/*
서울 30-50대 vip 회원 탑 10 (select+where+order by)
*/

proc sql outobs=10
	select user.id, name,  age, city, vip_grade, total_spent
	from shop.users
	where city = '서울' 
	and age between 30 and 50
	and vip_grade ='vip'
	order by total_spent desc;
quit;

Proc sql;
	select channel,
	count(*) as 회원수,
	count(disticnt yip_grade) as 등급수,
	avg(total_spent) 평균매출 format comma 15

Proc sql;
	select count(*) as 주문건수,
	sum(total_amount) as 총매출 format comma 12.2,
	avg(total_amount) as 객단 format comma 12.2,
	min(total_amount) as 최소

quit;
/*체널별 총주문수, 매출총액, 객단가*/
proc sql;
	select channel as 체널, count(*) as 총주문수, sum(total_amount) as 매출총액, mean(total_amount)
	as 객단가
	from shop.orders
	where status = 'paid'
	group by channel;
quit;


/*체널별 device별 총주문수, 매출총액, 객단가  */
proc sql;
	select channel as 체널, count(*) as 총주문수,
quit;

/* 고객의 등급별, 주문체널별 주문수, 매출총액*/
proc sql;
	select u.vip_grade as 고객등급, o.channel as 주문체널,
	count(o.order_id) as 총주문수
from shop.users;
quit;

/*  고객의 가입 체널명 매출총액 단, 매출총액이 500만원 이상인 체널만 매출총액이 많은 체널순으로 출력*/
proc sql;
	select channel, sum(total_amount) format comma15. as 매출총액
	from shop.orders
	group by channel
	having calculated 매출총액 > 21,000,000,000
order by 매출총액 desc;
quit;

/*고객별 누적매출, 주문술르 출력, 누적매출이 500만원 이상인 고객만, 20건만 출력
주문 건수가 1건 이상인 고객, 정상주문만 누적매출 많은 순서대로
*/
proc sql outobs = 20;
select * from shop.users;
quit;

proc sql;
	select year(order_date) as 연도, count(*) as 주문수, sum(total_amount) as 주문총액
	from shop.orders
	where status = 'paid'
	and calculated 연도 = 2026
	group by calculated 연도,  calculated 월
	order by 연도, 월;
quit;


/*날짜 함수 year(), month(), day(), qtr() 분기
intnx("month", order_date, 0 , 'B')-> 0:금월, 1:다음월, 'B':달의 첫날, 'E':마지막

고객명, 마지막 접속한 연, 월, 일, 분기, 접속한 달의 1일 출력 -> 20명의 정보만
*/

proc SQL outobs = 20;
	SELECT name, year(last_login_date) as 연도,
	month(last_login_date) as 월,
	DAY(last_login_date) as 일,
	qtr(last_login_date) as 분기,
	intnx('month',)	
	from shop.users
	where last_login_date is not null
	order by 연도, 월, 일;
quit;

/*월별 주문수, 매출총액을 영구 저장 -> monthly_kpi 테이블명*/
proc SQL;
	create table shop.monthly_kpi
	as select intnx('month', order_date, 0, 'b') format yymmdd7 as 월,
		count(*) as 주문수, sum(total_amount) as 매출액
		from shop.orders
		group by calculated 월
		order by 월;
quit;

proc SQL;
	create view shop.vw_monthly_kpi
	as select intnx('month', order_date, 0, 'b') format yymmdd7 as 월,
		count(*) as 주문수, sum(total_amount) as 매출액
		from shop.orders
		where calculated 월 >= 260701
		group by calculated 월
		order by 월;
quit;

proc SQL outobs = 10;
	select * from shop.vw_monthly_kpi;
quit;

proc SQL outobs = 1;
	select year(order_date), month(order_date)
	from shop.orders;
quit;

PROC SQL;
   CREATE TABLE shop.monthly_kpi_1 AS
   SELECT YEAR(order_date)*100 + MONTH(order_date) AS 년월,
   COUNT(*)  AS 주문수  FORMAT=COMMA10.,
   SUM(total_amount)  AS GMV  FORMAT=COMMA15.,
   AVG(total_amount)  AS AOV  FORMAT=COMMA12.,
   COUNT(DISTINCT user_id) AS MAU  FORMAT=COMMA10.
   FROM shop.orders
   GROUP BY CALCULATED 년월
   ORDER BY 년월;
QUIT;

PROC SQL OUTOBS=10;
   SELECT * FROM shop.monthly_kpi;
QUIT;

PROC SQL;
   CREATE VIEW shop.vw_channel_monthly_1 AS
   SELECT channel  AS 채널,
   YEAR(order_date)*100 + MONTH(order_date) AS 년월,
   COUNT(*)  AS 주문수  FORMAT=COMMA10.,
   SUM(total_amount)  AS 매출  FORMAT=COMMA15.
   FROM shop.orders
   WHERE order_date >= '01JAN2025'd
   GROUP BY channel, CALCULATED 년월
	order by 년월;
proc sql outobs=10;
	select * from shop.vw_channel_monthly_1;
quit;

proc sql outobs = 10;
select u.vip_grade as 고객등급, o.channel as 주문체널, count(o.order_id) as 총주문수, 
sum(o.total_amount* from shop.users as u inner join shop.orders as on
		on u.user_id = o.user_id
	where o.status = 'paid'
	group by u.vip_grade, o.channel
	order by o.channel;
quit;

/*고객명, 주문일자, 상품id, 주문고객을 출력 : 정상 거래만,
	users, orders, order_items join
order items.csv -> sas database로 shop_db에 저장 */
Proc import datafile="/home/student/shop_csv/order_items.csv"
	out = shop.order_items;
	dbms = csv
	replace;
	getnames= yes;
	guessingrows=1000;
	datarow=2;
Run;

/*2. 컬럼 정보 확인*/
proc sql outobs = 20;
	select u.name as 고객명, o.order_date format yymmdd10. as 주문일자,
			oi,product_id as 상품ID, p.product_name as 상품명, oi.line_total as 주문금액
	from shop.users as u inner join shop.orders as o on u.user_id = o.user_id
		inner join shop.order_items as oi on o.order_id = oi.order_id
		inner join shop.products as p on oi.product_id = p.product_id
	where o.status = 'paid'
	order by 3;
quit;

/*상품명별로 주문건수와 누적 주문금액을 출력*/
proc sql outobs = 20;
select 상품명, 누적 건수, 누적 주문금액

	/*COUNT(*)  AS 주문건수 FORMAT=COMMA10.,
   SUM(total_amount)  AS 누적 주문금액  FORMAT=COMMA15.,
*/
from shop.products as p inner join shop.order_items as oi on p.product_id = oi.product_id
group by p.product_name;
quit;

/*체널별 상품폄별 누적 주문금액 -> 상품별 체널별로 정렬*/
proc sql outobs = 20;
select o.channel as 체널, p.product_name as 상품명, sum(line_total) as 누적 주문 금액

from shop.products as p inner join shop.order_items as oi on p.product_id = oi.product_id
inner join shop.orders as o on o.order_id=oi.order_id
group by p.product_name, o.channel;
quit;

/*비활성 고객의 명단을 추출하려고 한다. 이름, 가입일자 출력*/
proc sql;
	select u.name as 이름, u.signup_date format yymmdd10 as 가입일자
	from shop.users as u left join shop.orders o on u.user_id o. u.user_id =o.user_id
	where o.user_id is null
	order by 2;
quit;

/*1. 상품명, 누적주문금액, 주문이 전혀 없는 상품도 출력 20건만
	2. 주문이 전혀 없는 상품명 출력
*/

proc sql outobs =20;
	select 상품명, 누적주문금액
	from shop. products as p left join shop.order_items as oi on p. product_id = oi.product.id
	group by p.product_name;
quit;

proc sql;
	select p. product_name as 상품명
	from shop.products as  p left join shop.order_items oi on p.product_id = oi.product_id
	where oi.product_id is null;
quit;
/*우리가 필요에 의해서 보여주지 않지만 조인이 필요한 경우가 있다.*/

/*pp.69 등급별 월별 매출 추세*/
PROC SQL;
   SELECT u.vip_grade AS 등급,
          YEAR(o.order_date) * 100
             + MONTH(o.order_date) AS 년월,
          COUNT(*) AS 주문수,
          SUM(o.total_amount) AS 매출 FORMAT=COMMA15.
   FROM shop.orders AS o
   INNER JOIN shop.users AS u
      ON o.user_id = u.user_id
   WHERE o.order_date >= '01JAN2025'd
     AND u.vip_grade IS NOT MISSING
     AND o.status = 'paid'
   GROUP BY u.vip_grade, CALCULATED 년월
   ORDER BY 등급, 년월;
QUIT;

PROC SQL;
   SELECT u.user_id AS 회원ID,
          u.name AS 이름,
          u.city AS 도시,
          u.signup_date AS 가입일 FORMAT=YYMMDD10.
   FROM shop.users AS u
   LEFT JOIN shop.orders AS o
      ON u.user_id = o.user_id
   WHERE u.signup_date >= '01JAN2025'd
     AND u.signup_date <  '01APR2025'd
     AND o.order_id IS NULL
   ORDER BY u.signup_date;
QUIT;

PROC SQL OUTOBS=10;
   CREATE TABLE shop.top_products AS
   SELECT p.product_name AS 상품,
          p.brand AS 브랜드,
          SUM(oi.quantity) AS 수량,
          SUM(oi.quantity * oi.unit_price)
             AS 매출 FORMAT=COMMA15.
   FROM shop.order_items AS oi
   INNER JOIN shop.products AS p
      ON oi.product_id = p.product_id
   INNER JOIN shop.orders AS o
      ON oi.order_id = o.order_id
   WHERE o.status = 'paid'
   GROUP BY p.product_id, p.product_name, p.brand
   ORDER BY 수량 DESC;
QUIT;
/*
%let csv_dir = /home/student/shop_csv; /* csv 원본 경로*/
%LET SAS_DIR = /home/student/shop_DB;	/*SAS 출력 경로*/
*/
/* ============================================================================
   m3_data_load.sas - M3 모듈 데이터 로드 (CSV → SAS 데이터셋)
   ----------------------------------------------------------------------------
   사용 시점: 모든 D1~D4 실습 전에 1 회만 실행
   
   기능:
   1) CSV 파일 (users / orders / order_items / products) 을 SAS 로 가져오기
   2) shop 라이브러리에 영구 .sas7bdat 형식으로 저장
   3) 데이터 검증 (행 수 + 컬럼 구조 확인)
   
   준비물:
   - CSV 4 개 파일이 /home/student/csv_source 에 있어야 함
     · users.csv         (회원 1,000 행)
     · orders.csv        (주문 5,000 행)
     · order_items.csv   (주문 상세)
     · products.csv      (상품 100 행)
   ============================================================================ */


/* ── 1. 경로 설정 ───────────────────────────────────────────────────────── */

%LET CSV_DIR  = /home/student/shop_csv;    /* CSV 원본 경로 */
%LET SAS_DIR  = /home/student/shop_db;      /* SAS 출력 경로 */

LIBNAME shop "&SAS_DIR";    /* shop 라이브러리 = 영구 저장소 */


/* ── 2. users.csv 로드 ─────────────────────────────────────────────────── */
/*  컬럼: user_id, name, age, city, vip_grade, signup_date, total_spent,
         order_count, gender, email                                          */

PROC IMPORT DATAFILE = "&CSV_DIR/users.csv"
            OUT      = shop.users
            DBMS     = CSV
            REPLACE;
   GETNAMES = YES;       /* 첫 행 = 컬럼명 */
   GUESSINGROWS = 1000;  /* 데이터 타입 추론을 위한 행 수 */
   DATAROW = 2;
RUN;

/* signup_date 가 문자로 들어오면 날짜로 변환 */
DATA shop.users;
   SET shop.users;
   FORMAT signup_date_d YYMMDD10.;
   IF VTYPE(signup_date) = 'C' THEN
      signup_date_d = INPUT(signup_date, ANYDTDTE10.);
   ELSE signup_date_d = signup_date;
RUN;


/* ── 3. orders.csv 로드 ────────────────────────────────────────────────── */
/*  컬럼: order_id, user_id, order_date, status, total_amount,
         channel, payment_method, ...                                        */

PROC IMPORT DATAFILE = "&CSV_DIR/orders.csv"
            OUT      = shop.orders
            DBMS     = CSV
            REPLACE;
   GETNAMES = YES;
   GUESSINGROWS = 5000;
   DATAROW = 2;
RUN;


/* ── 4. order_items.csv 로드 ───────────────────────────────────────────── */
/*  컬럼: item_id, order_id, product_id, quantity, unit_price, line_total   */

PROC IMPORT DATAFILE = "&CSV_DIR/order_items.csv"
            OUT      = shop.order_items
            DBMS     = CSV
            REPLACE;
   GETNAMES = YES;
   GUESSINGROWS = 10000;
   DATAROW = 2;
RUN;


/* ── 5. products.csv 로드 ──────────────────────────────────────────────── */
/*  컬럼: product_id, product_name, brand, price, category,
         category_id, stock, ...                                             */

PROC IMPORT DATAFILE = "&CSV_DIR/products.csv"
            OUT      = shop.products
            DBMS     = CSV
            REPLACE;
   GETNAMES = YES;
   GUESSINGROWS = 100;
   DATAROW = 2;
RUN;


/* ── 6. 로드 검증 ─────────────────────────────────────────────────────── */

TITLE "M3 데이터 로드 검증 - 행수 + 컬럼수 확인";
PROC SQL;
   SELECT
      memname AS 테이블,
      nobs AS 행수,
      nvar AS 컬럼수,
      crdate AS 생성일 FORMAT=YYMMDDS10.
   FROM DICTIONARY.TABLES
   WHERE libname = 'SHOP'
     AND memtype = 'DATA'
   ORDER BY memname;
QUIT;
TITLE;


/* ── 7. 샘플 확인 (각 테이블 5 행) ────────────────────────────────────── */

TITLE "users 샘플 (5 행)";
PROC SQL OUTOBS=5;
   SELECT * FROM shop.users;
QUIT;

TITLE "orders 샘플 (5 행)";
PROC SQL OUTOBS=5;
   SELECT * FROM shop.orders;
QUIT;

TITLE "order_items 샘플 (5 행)";
PROC SQL OUTOBS=5;
   SELECT * FROM shop.order_items;
QUIT;

TITLE "products 샘플 (5 행)";
PROC SQL OUTOBS=5;
   SELECT * FROM shop.products;
QUIT;

TITLE;


/* ── 8. 컬럼 카탈로그 (학습용 데이터 사전) ───────────────────────────── */

TITLE "M3 shop 라이브러리 컬럼 카탈로그";
PROC SQL;
   SELECT
      memname AS 테이블,
      name AS 컬럼,
      type AS 타입,
      length AS 길이,
      label AS 라벨
   FROM DICTIONARY.COLUMNS
   WHERE libname = 'SHOP'
   ORDER BY memname, varnum;
QUIT;
TITLE;


/* ============================================================================
   로드 완료 메시지
   ============================================================================ */
%PUT =====================================================;
%PUT M3 데이터 로드 완료;
%PUT - users        ;
%PUT - orders       ;
%PUT - order_items  ;
%PUT - products     ;
%PUT 라이브러리: shop (= &SAS_DIR);
%PUT 다음 단계: m3d1_lab.sas 부터 순차 실행;
%PUT =====================================================;


