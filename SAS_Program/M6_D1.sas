/*ML Day1~Day8 */
LIBNAME shop "/home/student/shop_db";

/*[STEP 1] churn 비율 확인*/
PROC FREQ DATA=shop.users;
TABLES churn / NOCUM;
RUN;

/* [STEP 2] 60/40 분할  */
/* (churn 비율 유지, Stratified) */
PROC SORT DATA=shop.users OUT=work.users_sorted;
BY churn; /* Stratify 기준 */
RUN;

PROC SURVEYSELECT DATA=work.users_sorted
OUT=work.split
SAMPRATE=0.60 /* 60% Train */
SEED=42 /* 재현성 */
OUTALL; /* 전체 출력 */
STRATA churn; /* Stratified */
RUN;

DATA work.train work.test;
SET work.split;
IF Selected=1 THEN OUTPUT work.train;
ELSE OUTPUT work.test;
RUN;

/* [STEP 4] 결과 확인 - 분할 결과 비율 검증 */
PROC FREQ DATA=work.train;
TABLES churn / NOCUM;
RUN;

PROC FREQ DATA=work.test;
TABLES churn / NOCUM;
RUN;
