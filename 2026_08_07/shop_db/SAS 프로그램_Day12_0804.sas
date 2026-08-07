/* session 1 : 결측치 처리 연습 */
LIBNAME shop "/home/student_shop_db";

Title "[S1.2] before - user_dirty 상태";
PROC SQL;
 	select count(*)				AS n_total
		sum(missing(email))		as n_email_null
		sum(missing(city))		as n_city_null
		sum(missing(age))		as n__null


/* 정제 전 데이터 확인 */

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


/* session 2 결측 검사*/
DATA WORK.users_chk;
	SET shop.users_dirty;


	/*단일 column 결측 검사*/
	if missing(age) then age_missing = 1;
	else				age_missing = 0;
	/* 여러 컬럼 결측 개수 (숫자) */
	nmiss_cnt =nmiss(age, email, city);

	/* 비결측치만 처리 */
	if not missing(age) and age > 0
		then age_valid = 1;
Run;

PROC print data=users_chk(obs = 10);
		var age total_spent nmiss_cnt cmiss_cnt age_valid;
run;
