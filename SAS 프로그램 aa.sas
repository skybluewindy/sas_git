LIBNAME SHOP "/HOME/STUDENT/SHOP_DB";

/*정상 지불인 주문의 주문금액 1000만 이상인 주문의 ORDER-ID, TOTAL AMOUNT, STATUS, CHANNEL */
PROC SQL OUTOBS =20;

SELECT ORDER_id, USER_ID, TOTAL_AMOUNT,STATUS, CHANNEL
FROM SHOP.ORDERS
WHERE STATUS = 'PAIN'
AND TOTAL_AMOUNT >= 100000;
QUIT;
/**/
/*지역이 서울, 부산 대구인 고객의 이름, 나이, 지역을 출력해보세요*/
PROC SQL OUTOBS=10;
 SELECT NAME, AGE, CITY
FROM SHOP.USERS
WHERE CITY IN ('서울', '부산','대구')
AND NAME LIKE '김%';
QUIT;

PROC SQL OUTTOPS=20;
	SELECT ORDER_ID, USER_ID, TOTAL_AMOUNT FORMAT COMMA 12.0, STATUS,
	channel, order_date format=YYMMDD10.
from shop.orders
where status = 'paid'
and total_amount >= 100000,
and channel in ('organic', 'direct')
order by order_date desc;
quit;

proc sql outobs=10;
	select channel
	from shop.orders
	quit;

/channel이 null인 고객들의 **/
proc sql;
	select name, channel	
	from shop.users
	where channel is null;
	quit;

/*등급별 총 금액출력, 이름, 등급, 총금액(total_spent)
	where channel is null;*/
/*등급별 총 금액출력, 이름, 등급, 총금액(total_spent) */
	
	proc sql outobs=20;
	select name as 고객명, vip_grade as 고객등급
	total_amount as 총금액
    from shop_users
	order by 2, 총금액 desc;
	quit;

/*proc sql outobs=20;
	select name as 고객명, vip_grade as 고객등급
	total_amount as 총금액
    from shop_users
	order by 2, 총금액 desc;
	quit;*/
libname shop "/home/student/shop_db";

/*
count(*), count(user_id), count(distinct user_id) orders
*/
proc sql
	select count(*) as 총 주문 수,
			count(user_id) as 고객 수,
			count(distinct user_id) as 유효고객수
			from shop.orders
quit;
/*도시종류를 구하는 데 count(*),  count(city) COUNT(DISTINCT CITY) 출력 -> USERS */

proc sql
	select COUNT(*) AS 고객수,
	COUNT(CITY) AS 도시 수,
	COUNT(DISTINCT CITY) 유니크 도시 수
	FROM SHOP.USERS;
QUIT;

/*체널 종류 구하기*/
proc sql
	SELECT COUNT(DISTINCT CHANNEL) AS 고객체널 종류
	FROM SHOP.USERS;
	SELECT COUNT(DISTINCT CHANNEL) AS 주문체널 종류
	FROM SHOP.ORDERS;
QUIT;


/* 전체 주문 수, 고객 수 , 인당 주문 수(전체 고객 수 /고객 수) 를 구하세요.
 SELECT SUM(total_amount) as 총주문금액, count(distinct user_id) as 고객 수,
	calculated 인당 주문 금액
*/

proc sql
	select sum(order_count(*) as 총 주문 수, count(distinct user_id) as 고객 수,
	calculated 총 주문 수 / calculated 고객 수 as 인당 주문 수
	from shop.users;
quit;

/* orders 에서 총주문금액, 주문고객수, 인당주문금액, 정상거래만 status = 'paid' */

proc sql;
	select sum(total_amount) format comma 20.0 as 총주문 금액, 
	count(distinct user_id) as 주문고객수
	calculated 총주문금액 / calculated 주문고객수 format comma12.0 as 고객 1인당 주문금액
	from shop.users
	where status = 'paid';

quit;

proc sql;
/* 연령이 60 이상이면 '시니어', 아니면 '청년' 출력, 이름, 나이, 연령대 */
select name as 이름, age as 나이,
	case when age >= 60 then '시니어'
	else '청년'
	end as 연령대
from shop.users
quit;

/*10대, 20대, 30대, 40대, 50대, 시니어 -> 연령대로 출력*/


proc sql;
/* 연령이 60 이상이면 '시니어', 아니면 '청년' 출력, 이름, 나이, 연령대 */
	select name as 이름, age as 나이,
		case when age <20 then '10대'
		when age <30 then '20대'
		when age <40 then '30대'
		when age <50 then '40대'
		when age <60 then '50대'
else '시니어'
end as 연령대
from shop.users
quit;

/*이름, 나이, 총주문금액(total) 출력
60 이상이면 시니어, 40이상이면 중장년, 20이상이면 청년 아니면 미성년 -> 연령대 
	total_spent >= 1000000 이상이면, 'vip'
100000 이상이면, '우수'
아니면 일반 -> 고객등급 */

proc sql outobs=20;
 select name as 이름, age as 나이, total_spent as 총주문금액,
	case when age >=60 then 'senior'
		when age >=40 then '중장년'
		when age >20 then '청년'
		else '미성년'
	end as 연령대,
	case when total_spent >= 1000000 then 'VIP'
		when total_spent >= 100000 이상이면, '우수'
		else '일반'
	end as 고객등급
 from shop.users;
quit;

/*0728*/