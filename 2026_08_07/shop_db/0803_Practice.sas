
data _null_;
    length new_path $300;
    new_path = dcreate("shop_data", "/home/student");
    put "생성된 경로: " new_path;
run;

%LET USERID = student;
%LET CSVNAME = users_dirty.csv;

%LET CSVPATH = /home/&USERID/shop_data/&CSVNAME;

DATA _NULL_;
    IF FILEEXIST("&CSVPATH") THEN
        PUT "NOTE: CSV 파일이 정상적으로 존재합니다. 경로=&CSVPATH";
    ELSE
        PUT "ERROR: CSV 파일을 찾을 수 없습니다. 경로=&CSVPATH";
RUN;


/*제2절-csv 업로드 완료 후 실행할 코드 */

/* 1. 사용자 폴더와 CSV 파일명 설정 */
%LET USERID = student;
%LET CSVNAME = users_dirty.csv;

/* 2. 전체 경로 생성 */
%LET CSVPATH = /home/&USERID/shop_data/&CSVNAME;

/* 3. 결과 데이터가 저장될 라이브러리 연결 */
LIBNAME mylib "/home/&USERID/shop_db";

/* 4. CSV 파일 존재 여부 확인 */
DATA _NULL_;
    IF FILEEXIST("&CSVPATH") THEN
        PUT "NOTE: CSV 파일 확인 완료: &CSVPATH";
    ELSE
        PUT "ERROR: CSV 파일을 찾을 수 없음: &CSVPATH";
RUN;

/* 5. CSV 파일 불러오기 */
PROC IMPORT
    DATAFILE="&CSVPATH"
    OUT=mylib.users
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    GUESSINGROWS=MAX;
RUN;

/* 6. 데이터 구조 확인 */
PROC CONTENTS DATA=mylib.users;
RUN;

/* 7. 앞부분 5행 확인 */
PROC PRINT DATA=mylib.users(OBS=5);
RUN;
/*제3절*/
/*
%LET USERID = student;  /* 본인의 SAS 홈 폴더명에 맞게 수정 */

LIBNAME mylib "/home/&USERID/shop_db";*/
/*&&&&&&&&&&&*/


%LET USERID = student;

LIBNAME mylib "/home/&USERID/shop_db";


/* 1. 제목·빈 행·원래 헤더를 건너뛰고 4행부터 가져오기 */
PROC IMPORT
    DATAFILE="/home/&USERID/shop_data/users_dirty.csv"
    OUT=work.users_raw
    DBMS=CSV
    REPLACE;
    GETNAMES=NO;
    DATAROW=4;
    GUESSINGROWS=MAX;
RUN;


/* 2. VAR1~VAR7을 의미 있는 변수명으로 정리 */
DATA mylib.users;

    /* 문자형 변수의 길이를 먼저 설정 */
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

    /* 고객ID가 문자형으로 읽혔을 가능성이 있으므로 숫자로 변환 */
    user_id = INPUT(STRIP(user_id_char), ?? BEST32.);

    /* 합계행·빈 행·작성일 행 제거 */
    IF MISSING(user_id) THEN DELETE;

    DROP user_id_char;

    /* 최종 변수 순서 지정 */
    RETAIN user_id user_name age city gender email total_spent;

RUN;


/* 3. 변수 구조 확인 */
PROC CONTENTS DATA=mylib.users;
RUN;


/* 4. 처음 10명 확인 */
PROC PRINT DATA=mylib.users(OBS=10) NOOBS;
    VAR user_id user_name age city gender email total_spent;
RUN;