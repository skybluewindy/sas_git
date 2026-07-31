%let Root = /home/student;
libname shop "&Root/shop_db";

/* shop.users 가져와서 user_copy로 */
Data user_copy;
	set shop.users;
run;


Proc sql outobs=5;
	select user_id, name, age, gender, city, channel
	from user_copy;
quit;

/*Proc print로 변경*/
title "user_copy 의 정보"
proc print data=user_copy(obs=5);
	var user_id name age gender city channel;
run;
title;


/*중간 결과는 work에 tax = total_spent * 0.1*/
data user;
		set shop.users;
		tax =total_spent * 0.1;
	run;

data shop.user_tax;
	set users;
run;

proc print data=shop.user_tax;
run;
quit;

/* shop.users 에서 user_id name age channel 컬럼만 추출 */
DATA users_kept;
	SET shop.users; 
	KEEP user_id name age channel;
Run;

/*total_spent order_count churn marketing_consents 칼럼 제외 */
Data users_dropped;
	set shop.users;
	Drop total_spent order_count churn marketing_consent;
Run;

Title "[S1.3] KEEP 결과 - 4 컬럼";
Proc print Data=work.users_dropped(OBS=5) NOOBS;
RUN;

title "users_kept과 users_dropped -> union all";
data orders_2025;
	set shop.orders;
	where order_data between '01JAN2026'd and '31DEC2026'd;


/*title title2,,...,title10*/
proc print DATA=shop.users (OBS=10)
noobs label double;

data users_all;
	set users_2025
		users_2026;
run;

data users_tagged
	set users_2025 (in=y25)
		users_2026 (in=y26);
	IF y25 then src="2025";
	else if y26 then src = "2026";
run;

Proc sort data=users_tagged nodupkey;
	by user_id;
run;

Proc print data=shop.orders(obs=5) noobs;
	var user_id order_id_DATE;
RUN;
%IMP(name=orders);
%imp(name=categories);

data orders_2026;
	set shop.orders;
 	where order_date between '01JAN2026' and '31DEC	2026'd;
RUN;

/* session 2 */
DATA work.users_safe;
	 set shop.users;

/* 1) MISSING 함수 */
IF MISSING(age) then age = 0;
if missinng(email) then email = "no-email;

/* 2) coalesce 첫 비결측*/
age_safe = coalesce(email, "UNKNOWN")
quit;
/* session 3*/
data user_grp;
	length are_grade $20
set shop.users;
if missing(age) then age = 0;
if age<20 then age_grade = '10대';

else if age < 30 then age = '20대'
Proc freq data=user_grp;
	tables age_grade /NOCUM;
RUN;
TITLE;


/*수도권으로 분류하고 아니면 기타 지역*/


/* 실습 5: 고객id, 이름, 지역, email, total_spent, gender 칼럼 출력,
이메일이 네이버이고, 30-50대 사이, 여성만, 지역은 서울 경기 이외의 지역에 있는 고객 정보만
excel 파일로 저장--> users_city.excel 파일로 저장
title -> 수도권 이외의 지역에 사는 여생 고객 정보
foot-> 2026.7.31 작성 

헤더는 고객id, 이름, 연령, 지역, 성별, 누적매출
총매출도 출력*/

/*시험문제 어떻게 나오는지는 이 과정 운영하시는 분들이 아주 자세히 알려주심.*/
/*숙제 제출 url
https://buly.kr/58Uo9Zd*/