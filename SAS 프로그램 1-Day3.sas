/* 이상치 탐지 z-score */

proc sql outobs = 15;

	select order_id as 주문ID,
	total_amount as 금액       



/*고객 등급이 'gold'인 회원이 주문한 주문번호, 주문금액, 고객번호 출력*/

proc sql outobs = 15;
	select order_id, user_id, total_amount
	from shop.orders
/* where user_id = (고객 등급이 gold인 회원번호)*/
	where user_id IN (SELECT user_id from shop.users where vip_grade = 'gold');
quit;

/* 휴면 고객의 회원번호, 이름, 가입일자 */
proc sql outobs = 15;
	select
	from
;quit;
/*활동 고객의 회원번호, 이름, 등급, 주문수*/
proc sql outobs =15;
	select user_id, name, vip_grade,
/*		(주문수) as 주문건수 */
		(select count(*) from ) 
from
order by 주문건수 desc;
quit;                                                                     