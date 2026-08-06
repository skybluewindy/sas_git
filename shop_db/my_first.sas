/* ==============================================
   my_first.sas
   M4 Day 1 종합 실습
   ============================================== */


/* 1. 사용자 폴더 설정 */
%LET USERID = student;


/* 2. 영구 라이브러리 연결 */
LIBNAME mylib "/home/&USERID/shop_db";


/* 3. CSV 불러오기
   1행: 문서 제목
   2행: 빈 행
   3행: 원래 변수명
   4행부터 실제 고객 데이터
*/
PROC IMPORT
    DATAFILE="/home/&USERID/shop_data/users_dirty.csv"
    OUT=work.users_raw
    DBMS=CSV
    REPLACE;
    GETNAMES=NO;
    DATAROW=4;
    GUESSINGROWS=MAX;
RUN;


/* 4. VAR1~VAR7을 올바른 변수명으로 정리 */
DATA mylib.users;

    /* 문자형 변수 길이를 먼저 지정 */
    LENGTH user_name $20
           city      $10
           gender    $1
           email     $40;

    SET work.users_raw
        (
            RENAME=
            (
                VAR1=user_id_char
                VAR2=user_name
                VAR3=age
                VAR4=city
                VAR5=gender
                VAR6=email
                VAR7=total_spent
            )
        );

    /* 문자형으로 들어온 고객 ID를 숫자로 변환 */
    user_id = INPUT(STRIP(user_id_char), ?? BEST32.);

    /* 고객 ID가 없는 합계행·빈 행·작성일 행 제거 */
    IF MISSING(user_id) THEN DELETE;

    DROP user_id_char;

RUN;


/* 5. 연령 그룹 변수 생성 */
DATA mylib.users_v2;

    LENGTH age_grp $6;

    SET mylib.users;

    /*
       현재 데이터의 연령 범위가 30~59세이므로
       30대, 40대, 50대 이상으로 구분
    */
    IF age < 40 THEN
        age_grp = "30대";

    ELSE IF age < 50 THEN
        age_grp = "40대";

    ELSE
        age_grp = "50대+";

    LABEL
        user_id     = "고객 ID"
        user_name   = "고객명"
        age         = "연령"
        age_grp     = "연령대"
        city        = "지역"
        gender      = "성별"
        email       = "이메일"
        total_spent = "누적매출";

RUN;


/* 6. 조건에 맞는 고객 10명 출력 */
TITLE "40세 이상이며 누적매출이 100만원 이상인 고객 10명";

PROC PRINT
    DATA=mylib.users_v2(OBS=10)
    NOOBS
    LABEL;

    VAR
        user_id
        user_name
        age
        age_grp
        city
        gender
        total_spent;

    WHERE age >= 40
      AND total_spent >= 1000000;

    FORMAT total_spent COMMA15.;

RUN;


/* 7. 제목 해제 */
TITLE;