libname shop "/home/student/shop_db";


Proc  sql;
	create table shop.monthly_kpi as select
		intnx('MONTH', ORDER_DATE, 0, 'b')
		as 월 FORMAT = YYMMDD7.,
		COUNT(*) AS 주문수,
		SUM(total_amount) as 매출 FORMAT DOLLAR12.,
		AVG(total_amount) as 객단가
		FORMAT DOLLAR12.
	FROM shop.orders
	where status = 'paid'
	Group by INTNX('MONTH', order_date, 0, 'B');
quit;

Proc sql noprint;
	select count(*) into :n_users
	from shop.users;
quit;

%put 회원수 : &n_users;

proc sql noprint;
 	select user_id into :vip_list
	from shop.users
	where vip_grade = 'gold';
	quit;

%put vip_list : &vip_list;

proc sql outobs=10;
 	select user_id, vip_grade
	from shop.users
	where user_id in (&vip_list);
quit;

%LET tbl = shop.users;
PROC SQL outobs = 10;
	select user_id, vip_grade
	from %tbl
	where user_id in (&vip_list);

/*count  into나 %let으로 변수 선언하게 되면
그 변수에다 다른 값을 집어넣지 않는 한, 계속 다시 사용할 수 있다.*/

quit;

/* 2026년 01월 이후 주문한 내역만 출력을 해볼 것*/
%LET day = '01JAN26'd;

PROC SQL;
	SELECT * FROM SHOP.orders
	where order_date > &day;
quit;

%LET year = 2026;
proc sql;
		create table shop.kpi_&year as
		select * from shop.orders
		where order_date > &day;
quit;


/* 사용자 이름(고객명), 고객의 매출 총합, 마지막 주문 일자, 주문 건수를 출력
1단계 : users에서 gold 또는 vip 회원의 명단만 동적변수에 저장 후
2단계 : 1단계에서 저장한 고객만 해당 자료 추출 
1단계 : 고객(회원)id 추출 -> vip_list
*/
proc sql noprint;
	
	select user_id into :vip_list separated by ',' from shop.users
	where vip_grade = 'gold'
	order by vip_grade;
quit;

proc sql outobs = 20;
	select u.name as 고객명, u.total_spent as 고객의매출총합,
		(select max(order_date) from shop.orders
		where user_id = u.user_id) as 마지막주문일자,
		(select count(*) from shop.orders where user_id = u.user_id) as 주문건수
	from shop.users u
	where u.user_id in (&vip_list);
quit;

/* 라이브러리 검색*/
/* 먼저 테이블 정보 확인*/
proc sql;
	select memname, nobs 행수, create as 생성일
	from dictionary.tables;
	where libname = 'SHOP';
quit;



proc sql outobs=10;
	select * from dictionary.tables;
quit;


/* 칼럼 정보는 dictionary.columns */

proc sql;
	select memname as 테이블명, name as 컬럼명, type as 데이터타입, length as 길이
	from dictionary.columns
	where libname ='SHOP'
	and memname IN =('USERS','ORDERS';
quit;

/* dictionary tables의 컬럼 정보 확인*/
proc sql;
	select name as 컬럼명, type as 데이터타입, length as 길이
	from dictionary.columns
	where libname ='SHOP'
	and upcase(name) like '%USER_ID%' ;
quit;

proc sql;
	select libname, count(*) as 테이블의개수, sum(nobs) as 총행의 수
	from dictionary.tables
/* index 정보를 보자 */

/*딕셔너리의 테이블과 컬럼의 정보 검색*/

/* 데이터 카탈로그 자동 생성 */ 
PROC SQL;
SELECT t.memname AS 테이블, t.nobs AS 행수, t.crdate AS 생성일 FORMAT=YYMMDD10.,
COUNT(c.name) AS 컬럼수
FROM DICTIONARY.TABLES AS t LEFT JOIN DICTIONARY.COLUMNS 
AS c ON t.libname = c.libname AND t.memname = c.memname WHERE t.libname = 'SHOP'
GROUP BY t.memname, t.nobs, t.crdate
ORDER BY t.memname;

QUIT;

PROC sql;
	select * from dictionary.indexes;
	where libname = 'SHOP';
QUIT;

options fullstimer msglevel=i;


/*user_id가  42인 고객의 정보 출력*/
proc sql;
	select * from shop.orders
	where user_id = 42;
quit;
/* 인덱스 생성 전*/
proc sql _method;
	select * from shop.orders
	where user_id = 42;
quit;

/* 인덱스 생성->orders 의 user_id 컬럼*/
proc sql;
	create index user_id = 42;
quit;


proc datasets lib=shop nolist;
	modify orders;
	drop index user_id;/* 삭제할 인덱스(또는 컬럼명) 지정 */
	repair orders;
quit;


proc sql;
	select * from dictionary.indexes where libname = 'SHOP';
quit;


/*주문 상품명, 총주문 금액 출력 -> order_items (product_id, line_total) product_name) */
proc sql outobs = 20 _method;
	select p.product_name as 상품명,
	sum(oi.line_total) as 주문총액
	from shop.order_id

/*orders->user_id, order_date 복합 인덱스 생성 : idx_user_date 
고객명, 주문일자, 주문총액
고객id가 42인 고객의 주문 중 260101 이후 주문한 내용만 주문일자로 정렬
*/
proc sql _method;
	select name as 고객명, order_date, sum(total_amount) as 총주문액
	from shop.orders o inner join shop.users u on o.user_id =  u.user_id
	where o.user_id = 42
	and o.order_date >= '01JAN2026'd
group by order_date, o.user_id;
quit;

DATA cust_seg;
	SET cust_sales;
	LENGTH 등급 $10 캠페인 $30;
	IF 총매출 >= 1000000 THEN DO;
	등급 = 'VIP';    캠페인 = 'VIP 행사 초대';
	END;
	ELSE IF 총매출 >= 500000 THEN DO;등급 = 'gold';
   	캠페인 = '신상품 우선 안내'; END; ELSE IF 총매출 >= 100000 THEN DO;등급 = 'Silver';
	캠페인 = '10% 할인 쿠폰'; END; ELSE DO;등급 = 'Bronze'; 캠페인 = '복귀 30% 쿠폰'; END;
	RUN;

options fullstimer msglevel=N;

/**/
Proc sql;
	create table cust_sale AS
	select user_id,
		count(*) as 주문수,
		sum(total_amount) as 총매출
		from shop.orders where status ='paid'
		group by user_id;
quit;

proc sql outobs = 20;
	select * from cust_seg;
quit;

/* 빈도, 비율, 백분율 계산하는 proc freq*/
proc freq data = cust_seg;
	tables 등급;
run;


/* 고객의 첫 주문내역 user_id, order_id, order_date, total_amount 출력*/
proc sort data =shop.orders
	out = sorted_orders;
	by user_id order_date;
run;

data first_orders;
	set work.sorted_orders;
	by user_id;
	if first.user_id;
run;

/* 누적 매출 cum_orders 생성 고객별 */
data com_orders;
	set sorted_orders;
	by user_id
	retain 누적매출 0;
	if first.user_id then 누적매출 = 0;
	누적매출 + total_amount;
run;


/*마지막 사용한 날짜와 주문금액*/
proc sql outobs=20;
	select f.user_id as 고객번호, f.order_date as 첫주문일자, f.total_amount as 첫주문금액,
	l.order_date as 마지막주문일, l.total_amount as 마지막주문금액
	from first_orders f inner join last_orders 1 on f.user_id = 1.user_id;
quit;

Proc sql outobs = 20;
	select user_id, order_date, total_amount, 누적매출
	from cum_orders;
quit;

/* 세스 BASE VS VIYA CAS 속도 비교*/
OPTION FULLTIMER;

/* CAS 환경*/
CAS MYSESSION;
CASLIB_ALL-ASSIGN;

PROC CAS;
	BUILTINS.SERVERSTATUS;
quit;

proc casutil;
	load data=shop.orders outcalib="casuser"
		casout="orders" replace;
	load data=shop.users outcalib="casuser"
quit;
proc casutil;
	load data=shop.orders outcaslib="public"
		casout="orders" promote;
quit;


CAS mysession terminate;
*/cloud Analytic Services*/