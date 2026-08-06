/* 영구 라이브러리 연결 */
LIBNAME shop "/home/student/shop_db";


/* 사용자 데이터 구조 확인 */
PROC CONTENTS DATA=shop.users;
RUN;


/* 주문 데이터 구조 확인 */
PROC CONTENTS DATA=shop.orders;
RUN;


/* 실제 데이터 앞부분 확인 */
PROC PRINT DATA=shop.users(OBS=5) NOOBS;
RUN;

PROC PRINT DATA=shop.orders(OBS=5) NOOBS;
RUN;

/* =========================================
   SHOP 라이브러리의 모든 데이터셋 확인
   ========================================= */

PROC SQL;
    SELECT
        memname AS 데이터셋명,
        nobs    AS 행수,
        nvar    AS 변수수
    FROM dictionary.tables
    WHERE libname = 'SHOP'
      AND memtype = 'DATA'
    ORDER BY memname;
QUIT;


/* 강의용 원본으로 보이는 데이터 확인 */
PROC CONTENTS DATA=shop.users_dirty VARNUM;
RUN;

PROC PRINT DATA=shop.users_dirty(OBS=10) NOOBS;
RUN;


/* 수업 중 정제된 결과로 보이는 데이터 확인 */
PROC CONTENTS DATA=shop.users_clean VARNUM;
RUN;

PROC PRINT DATA=shop.users_clean(OBS=10) NOOBS;
RUN;

/**/
/* 과제용 임시 원본 생성 */
DATA work.users_hw;
    SET shop.users_dirty;
RUN;


/* 구조 확인 */
PROC CONTENTS DATA=work.users_hw VARNUM;
RUN;


/* 앞부분 확인 */
PROC PRINT DATA=work.users_hw(OBS=5) NOOBS;
RUN;
/*******/
/* =============================================
   실습 1 - 결측 처리 종합
   원본 : work.users_hw
   결과 : work.users_imputed
   ============================================= */


/* 1. 보정 전 결측 개수 확인 */
TITLE "[실습 1] 결측 보정 전";

PROC SQL;
    SELECT
        COUNT(*)                  AS 전체행수,
        SUM(MISSING(vip_grade))   AS vip_grade_결측,
        SUM(MISSING(total_spent)) AS total_spent_결측,
        SUM(MISSING(email))       AS email_결측
    FROM work.users_hw;
QUIT;

TITLE;


/* 2. 결측값 보정 */
DATA work.users_imputed;
    SET work.users_hw;

    /* 문자형 결측 보정 */
    vip_grade = COALESCEC(vip_grade, 'none');

    /* 숫자형 결측 보정 */
    total_spent = COALESCE(total_spent, 0);

    /* 이메일 결측 보정 */
    IF MISSING(email) THEN
        email = 'unknown';
RUN;


/* 3. 보정 전후를 한 표로 비교 */
TITLE "[실습 1] 결측 보정 전후 비교";

PROC SQL;
    CREATE TABLE work.missing_compare AS

    SELECT
        'BEFORE' AS 단계 LENGTH=10,
        COUNT(*)                  AS 전체행수,
        SUM(MISSING(vip_grade))   AS vip_grade_결측,
        SUM(MISSING(total_spent)) AS total_spent_결측,
        SUM(MISSING(email))       AS email_결측
    FROM work.users_hw

    UNION ALL

    SELECT
        'AFTER' AS 단계,
        COUNT(*)                  AS 전체행수,
        SUM(MISSING(vip_grade))   AS vip_grade_결측,
        SUM(MISSING(total_spent)) AS total_spent_결측,
        SUM(MISSING(email))       AS email_결측
    FROM work.users_imputed;
QUIT;

PROC PRINT DATA=work.missing_compare NOOBS;
RUN;

TITLE;


/* 4. 교재에서 요구한 숫자 결측 NMISS 비교 */
TITLE "[실습 1] total_spent 보정 전";

PROC MEANS DATA=work.users_hw N NMISS;
    VAR total_spent;
RUN;

TITLE "[실습 1] total_spent 보정 후";

PROC MEANS DATA=work.users_imputed N NMISS;
    VAR total_spent;
RUN;

TITLE;


/* 5. 결과 일부 확인 */
PROC PRINT DATA=work.users_imputed(OBS=10) NOOBS;
    VAR user_id name vip_grade total_spent email;
    FORMAT total_spent COMMA15.;
RUN;

/* =============================================
   실습 2 - 이상치 IQR + Winsorize
   원본 : shop.orders
   결과 : work.orders_capped
   ============================================= */


/* 1. 원본 주문금액 분포 확인 */
TITLE "[실습 2] Winsorize 전 주문금액 분포";

PROC MEANS DATA=shop.orders
    N NMISS MIN Q1 MEDIAN Q3 MAX MEAN MAXDEC=2;

    VAR total_amount;
RUN;

TITLE;


/* 2. Q1과 Q3 추출 */
PROC UNIVARIATE DATA=shop.orders NOPRINT;
    VAR total_amount;

    OUTPUT OUT=work.qstat
        Q1=q1
        Q3=q3;
RUN;


/* 추출된 Q1, Q3 확인 */
TITLE "[실습 2] Q1과 Q3";

PROC PRINT DATA=work.qstat NOOBS;
    VAR q1 q3;
    FORMAT q1 q3 COMMA15.2;
RUN;

TITLE;


/* 3. IQR 경계 계산과 Winsorize */
DATA work.orders_capped;

    LENGTH cap_type $20;

    /*
       work.qstat은 한 행짜리 통계 데이터입니다.
       첫 반복에서 q1과 q3을 가져옵니다.
    */
    IF _N_ = 1 THEN
        SET work.qstat(KEEP=q1 q3);

    SET shop.orders;

    /* 변경 전 금액 보관 */
    original_amount = total_amount;

    /* IQR과 하한·상한 */
    iqr   = q3 - q1;
    lower = q1 - 1.5 * iqr;
    upper = q3 + 1.5 * iqr;

    /* 결측값을 하한으로 잘못 바꾸지 않도록 검사 */
    IF NOT MISSING(total_amount) THEN DO;

        IF total_amount < lower THEN DO;
            outlier_flag = 1;
            cap_type = '하한 캡핑';
            total_amount = lower;
        END;

        ELSE IF total_amount > upper THEN DO;
            outlier_flag = 1;
            cap_type = '상한 캡핑';
            total_amount = upper;
        END;

        ELSE DO;
            outlier_flag = 0;
            cap_type = '정상 범위';
        END;

    END;

    ELSE DO;
        outlier_flag = .;
        cap_type = '결측';
    END;

RUN;


/* 4. 이상치 행 수 확인 */
TITLE "[실습 2] IQR 범위 밖 주문 수";

PROC FREQ DATA=work.orders_capped;
    TABLES outlier_flag cap_type / NOCUM MISSING;
RUN;

TITLE;


/* 숫자로 요약 */
PROC SQL;
    SELECT
        COUNT(*)          AS 전체주문수 FORMAT=COMMA12.,
        SUM(outlier_flag) AS 캡핑주문수 FORMAT=COMMA12.
    FROM work.orders_capped;
QUIT;


/* 5. Winsorize 후 분포 */
TITLE "[실습 2] Winsorize 후 주문금액 분포";

PROC MEANS DATA=work.orders_capped
    N NMISS MIN Q1 MEDIAN Q3 MAX MEAN MAXDEC=2;

    VAR total_amount;
RUN;

TITLE;


/* 6. 실제로 변경된 값 일부 확인 */
TITLE "[실습 2] 캡핑된 주문 일부";

PROC PRINT
    DATA=work.orders_capped
         (WHERE=(outlier_flag=1) OBS=20)
    NOOBS;

    VAR order_id
        original_amount
        total_amount
        cap_type
        lower
        upper;

    FORMAT original_amount
           total_amount
           lower
           upper
           COMMA15.2;
RUN;

TITLE;

/* =============================================
   실습 3 - 문자 정제 파이프라인
   원본 : work.users_hw
   결과 : work.users_clean
   ============================================= */


/* 1. 문자 정제 */
DATA work.users_clean;

    /*
       새 문자형 변수는 SET 전에 LENGTH를 지정합니다.
       UTF-8 한글 잘림을 방지하기 위해 길이를 여유 있게 설정합니다.
    */
    LENGTH
        name_clean   $60
        email_clean  $100
        email_domain $60
        city_clean   $60;

    SET work.users_hw;

    /* 이름에 들어 있는 공백 제거 */
    name_clean = COMPRESS(name, ' ');

    /* 이메일 양끝 공백 제거 + 소문자 통일 */
    email_clean = LOWCASE(STRIP(email));

    /* 이메일 도메인 오타 표준화 */
    email_clean =
        TRANWRD(email_clean,
                'gmail.co.kr',
                'gmail.com');

    /* 이메일 도메인 추출 */
    email_domain =
        SCAN(email_clean, 2, '@');

    /* 도시명 표준화 */
    city_clean =
        TRANWRD(STRIP(city),
                '서울특별시',
                '서울');

RUN;


/* 2. 정제 결과 일부 확인 */
TITLE "[실습 3] 문자 정제 전후";

PROC PRINT DATA=work.users_clean(OBS=20) NOOBS;

    VAR user_id
        name
        name_clean
        email
        email_clean
        email_domain
        city
        city_clean;
RUN;

TITLE;


/* 3. 도시 정제 전후 분포 */
TITLE "[실습 3] 도시명 정제 전";

PROC FREQ DATA=work.users_hw ORDER=FREQ;
    TABLES city / NOCUM MISSING;
RUN;

TITLE "[실습 3] 도시명 정제 후";

PROC FREQ DATA=work.users_clean ORDER=FREQ;
    TABLES city_clean / NOCUM MISSING;
RUN;

TITLE;


/* 4. 이메일 도메인 분포 */
TITLE "[실습 3] 정제된 이메일 도메인";

PROC FREQ DATA=work.users_clean ORDER=FREQ;
    TABLES email_domain / NOCUM MISSING;
RUN;

TITLE;


/* 5. gmail.co.kr이 남아 있는지 검사 */
PROC SQL;
    SELECT
        SUM(INDEX(LOWCASE(email), 'gmail.co.kr') > 0)
            AS 정제전_gmail_co_kr,

        SUM(INDEX(email_clean, 'gmail.co.kr') > 0)
            AS 정제후_gmail_co_kr

    FROM work.users_clean;
QUIT;


/* =============================================
   실습 4 - 날짜 변환 + 경과월
   원본 : work.users_hw
   결과 : work.users_date
   ============================================= */

DATA work.users_date;

    LENGTH 가입코호트 $6;

    SET work.users_hw;

    /* 날짜에서 연·월·주 추출 */
    가입년 = YEAR(signup_date);
    가입월 = MONTH(signup_date);
    가입주 = WEEK(signup_date);

    /* 가입일부터 오늘까지 지난 월 경계 수 */
    경과월 =
        INTCK('MONTH',
              signup_date,
              TODAY());

    /*
       가입일의 한 달 뒤 같은 일자
       교재의 3인수 INTNX는 다음 달 1일이 될 수 있으므로
       다음 결제일 의미에 맞게 SAME을 추가했습니다.
    */
    다음달 =
        INTNX('MONTH',
              signup_date,
              1,
              'SAME');

    /* 예: 202402 */
    가입코호트 =
        PUT(signup_date, YYMMN6.);

    /* 미래 가입일 이상 여부 */
    미래가입여부 =
        (signup_date > TODAY());

    FORMAT signup_date
           다음달
           YYMMDD10.;

RUN;


/* 1. 결과 일부 확인 */
TITLE "[실습 4] 날짜 파생변수";

PROC PRINT DATA=work.users_date(OBS=20) NOOBS;

    VAR user_id
        name
        signup_date
        가입년
        가입월
        가입주
        경과월
        다음달
        가입코호트
        미래가입여부;
RUN;

TITLE;


/* 2. 가입연도 분포 */
TITLE "[실습 4] 가입연도 분포";

PROC FREQ DATA=work.users_date;
    TABLES 가입년 / NOCUM MISSING;
RUN;

TITLE;


/* 3. 가입 코호트 분포 */
TITLE "[실습 4] 가입 코호트 분포";

PROC FREQ DATA=work.users_date ORDER=FORMATTED;
    TABLES 가입코호트 / NOCUM MISSING;
RUN;

TITLE;


/* 4. 경과월 통계 */
TITLE "[실습 4] 가입 후 경과월";

PROC MEANS DATA=work.users_date
    N NMISS MIN MAX MEAN MEDIAN MAXDEC=2;

    VAR 경과월;
RUN;

TITLE;


/* 5. 미래 가입일 수 확인 */
PROC FREQ DATA=work.users_date;
    TABLES 미래가입여부 / NOCUM MISSING;
RUN;

/* =============================================
   실습 5 - PROC FORMAT 사용자 정의
   원본 : work.users_hw
   결과 : 출력 시 한글 등급 표시
   ============================================= */


/* 1. 문자형 사용자 정의 포맷 생성 */
PROC FORMAT;

    VALUE $vip_fmt
        'vip'      = '최우수'
        'platinum' = '플래티넘'
        'gold'     = '골드'
        'silver'   = '실버'
        'bronze'   = '브론즈';

RUN;


/* 2. 포맷 적용 전 출력 */
TITLE "[실습 5] 포맷 적용 전";

PROC PRINT DATA=work.users_hw(OBS=20) NOOBS;

    VAR user_id
        name
        vip_grade
        total_spent;

    FORMAT total_spent COMMA15.;

RUN;

TITLE;


/* 3. 포맷 적용 후 출력 */
TITLE "[실습 5] VIP 등급 한글 표시";

PROC PRINT DATA=work.users_hw(OBS=20) NOOBS;

    VAR user_id
        name
        vip_grade
        total_spent;

    FORMAT vip_grade  $vip_fmt.
           total_spent COMMA15.;

RUN;

TITLE;


/* 4. VIP 등급 빈도표에도 포맷 적용 */
TITLE "[실습 5] VIP 등급별 고객 수";

PROC FREQ DATA=work.users_hw ORDER=FREQ;

    TABLES vip_grade / NOCUM MISSING;

    FORMAT vip_grade $vip_fmt.;

RUN;

TITLE;