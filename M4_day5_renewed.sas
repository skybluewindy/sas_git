/* ==========================================================================
   m4d5_lesson.sas — M4 Day 5 강사용 (강의 슬라이드 순서)
   --------------------------------------------------------------------------
   주제 : 매크로 + ODS 보고서 자동화
          %LET · %MACRO · %DO · %IF · INTO · ODS PDF · ODS EXCEL

   ★ 강의 슬라이드 흐름 (Session 1 → 7)
      Session 1  매크로 필요성 + %LET + 시스템 매크로 변수
      Session 2  %MACRO 정의 + 매개변수 + %PUT 디버깅 + 실수 TOP 5
      Session 3  %DO 반복 + %IF 조건 + %DO %WHILE/%UNTIL
      Session 4  INTO :변수 (단일/SEPARATED BY/인덱스) → 동적 매크로
      Session 5  ODS PDF (기본·STYLE·STARTPAGE·한글)
      Session 6  ODS EXCEL (시트별) + 종합 매크로
      Session 7  정리 + D6 예고

   ★ 사용 데이터 — setup_data.py
      shop.users           channel · vip_grade · age · total_spent
      shop.orders          status='paid' · total_amount · channel
      shop.kpi_channel_v6  D4 채널 KPI (영구)

   사용법: USERID 본인 OnDemand ID 로 치환 → F3
   ========================================================================== */

LIBNAME shop "/home/student/shop_db";


/* ── S0  사전 준비 - kpi_channel_v6 생성 (M4 D4 결과 영구화) ───────
   본 lesson 의 Session 5/6 예시에서 사용하는 shop.kpi_channel_v6
   가 없으면 자동 생성 (이미 있으면 SKIP).
   ──────────────────────────────────────────────────────────── */
%MACRO ensure_kpi;
   %IF NOT %SYSFUNC(EXIST(shop.kpi_channel_v6)) %THEN %DO;
      %PUT [S0] shop.kpi_channel_v6 가 없음 → 신규 생성;
      PROC SUMMARY DATA=shop.users NWAY;
         CLASS channel;
         VAR total_spent;
         OUTPUT OUT=shop.kpi_channel_v6 (DROP=_TYPE_ _FREQ_)
                N    = 고객수
                MEAN = 평균매출
                SUM  = 총매출;
      RUN;
   %END;
   %ELSE %DO;
      %PUT [S0] shop.kpi_channel_v6 이미 존재 - SKIP;
   %END;
%MEND;
%ensure_kpi;


/* ##########################################################################
   ## SESSION 1 — 매크로 필요성 + %LET (50분)
   ##                슬라이드 4~8 · 왜 매크로 · %LET · 시스템 변수
   ########################################################################## */

/* ── S1.1  왜 매크로가 필요한가 ─────────────────────────── */
/* 코드 중복 제거 :
     5 채널 × 동일 PROC SQL → 코드 5번 복사  X
     %MACRO ch_kpi(ch=); ... %MEND;  → 1 정의 + 5 호출  O */


/* ── S1.2  %LET — 매크로 변수 정의 + 해상도 ──────────── */
%LET TARGET  = paid;
%LET MIN_AMT = 50000;
%LET TOP_N   = 10;

%PUT TARGET  = &TARGET;
%PUT MIN_AMT = &MIN_AMT;
%PUT TOP_N   = &TOP_N;

TITLE "[S1.2] LET 사용 — &TARGET 주문 &MIN_AMT+ TOP &TOP_N";
PROC SQL OUTOBS=&TOP_N;
   SELECT order_id, user_id, total_amount, channel
   FROM shop.orders
   WHERE status = "&TARGET"
     AND total_amount >= &MIN_AMT
   ORDER BY total_amount DESC;
QUIT;
TITLE;


/* ── S1.3  시스템 매크로 변수 — &SYSDATE · &SYSTIME ──── */
%PUT SYSDATE  = &SYSDATE   (오늘 날짜);
%PUT SYSTIME  = &SYSTIME   (현재 시간);
%PUT SYSDAY   = &SYSDAY    (요일);
%PUT SYSUSERID = &SYSUSERID (본인 ID);

TITLE "[S1.3] 시스템 매크로 변수 — &SYSDATE &SYSDAY 보고서";
PROC PRINT DATA=shop.users (OBS=5) NOOBS;
   VAR user_id name age channel;
RUN;
TITLE;


/* ── S1.4  ★ 미니 실습 1 — %LET 동적 파일명 (10분) ── */
/* [목표] %LET 으로 YYYYMM + CUTOFF 정의 후 TITLE/WHERE/FILE 에 적용
   [산출물] 월별 매출 TOP N 보고서 (자동 파일명)              */
%LET YYYYMM = 202611;
%LET CUTOFF = 100000;
%LET ROOT   = /home/student/reports;

ODS PDF FILE="&ROOT/&YYYYMM._매출.pdf";
TITLE "&YYYYMM 월간 매출 (CUTOFF=&CUTOFF)";
DATA work.month;
   SET shop.orders;
   WHERE PUT(order_date, YYMMN6.) = "&YYYYMM"
     AND total_amount >= &CUTOFF;
RUN;
PROC PRINT DATA = work.month (OBS=20) NOOBS; RUN;
TITLE;
ODS PDF CLOSE;


/* ##########################################################################
   ## SESSION 2 — %MACRO + 매개변수 (50분)
   ##                슬라이드 9~13 · %MACRO · 매개변수 · %PUT 디버깅
   ########################################################################## */

/* ── S2.1  %MACRO — 코드 블록을 함수로 ─────────────── */
%MACRO ch_kpi(ch=);
   TITLE "[S2.1] &ch 채널 KPI";
   PROC SQL;
      SELECT "&ch"           AS channel LENGTH=15,
             COUNT(*)         AS n_orders,
             SUM(total_amount) AS total FORMAT=COMMA15.
      FROM shop.orders
      WHERE status = 'paid'
        AND channel = "&ch";
   QUIT;
   TITLE;
%MEND ch_kpi;

%ch_kpi(ch=organic);
%ch_kpi(ch=paid_search);
%ch_kpi(ch=social);


/* ── S2.2  다중 매개변수 + 기본값 ─────────────────── */
%MACRO ch_age_kpi(ch=organic, lo=20, hi=60, top=10);
   TITLE "[S2.2] &ch (&lo~&hi 세) TOP &top";
   PROC SQL OUTOBS=&top;
      SELECT u.user_id, u.name, u.age, o.total_amount
      FROM shop.users  AS u
      INNER JOIN shop.orders AS o ON u.user_id = o.user_id
      WHERE u.channel = "&ch"
        AND u.age BETWEEN &lo AND &hi
        AND o.status = 'paid'
      ORDER BY o.total_amount DESC;
   QUIT;
   TITLE;
%MEND ch_age_kpi;

%ch_age_kpi();                              /* 모든 기본값 */
%ch_age_kpi(ch=social, lo=20, hi=29);
%ch_age_kpi(ch=email, top=5);


/* ── S2.3  %PUT 디버깅 + 매크로 옵션 ─────────────── */
OPTIONS MPRINT MLOGIC SYMBOLGEN;   /* 디버깅 모드 — LOG 자세히 */

%MACRO test_macro;
   %PUT *** 매크로 시작;
   %LET x = 100;
   %PUT x = &x;
   %PUT *** 매크로 종료;
%MEND test_macro;

%test_macro;

OPTIONS NOMPRINT NOMLOGIC NOSYMBOLGEN; /* 디버깅 끄기 */


/* ── S2.4  매크로 실수 TOP 5 ─────────────────────── */
/* ① %MEND 누락 → LOG: "ERROR: %MACRO statement missing %MEND"
   ② 작은따옴표 안 &변수 → 해석 X
   ③ 매크로 정의만 + 호출 누락
   ④ 매크로 변수 + 일반 텍스트 연결 (&변수text → 오인식)
      해결 : &변수..text 또는 &변수%STR(text)
   ⑤ 중첩 매크로 — 가능하지만 복잡 (단순화 권장) */


/* ── S2.5  VIP 등급별 매크로 — KPI 집계 (기반 매크로, Session 3/4/6 재사용) ── */
%MACRO vip_kpi(grade=);
   TITLE "[S2.5] &grade 등급 통계";
   PROC SQL;
      SELECT "&grade"        AS vip_grade LENGTH=10,
             COUNT(*)         AS n_users,
             AVG(total_spent) AS avg_spent FORMAT=COMMA12.,
             AVG(order_count) AS avg_orders FORMAT=8.1
      FROM shop.users
      WHERE vip_grade = "&grade";
   QUIT;
   TITLE;
%MEND vip_kpi;

%vip_kpi(grade=bronze);
%vip_kpi(grade=silver);
%vip_kpi(grade=gold);
%vip_kpi(grade=platinum);
%vip_kpi(grade=vip);


/* ── S2.5-실습  ★ 미니 실습 2 — VIP 등급별 보고서 매크로 (10분) ── */
/* [목표] %MACRO 로 "vip 등급별 보고서" 함수화 (등급을 인자로)
   [산출물] %vip_report(grade=gold) 한 줄 호출                */
%MACRO vip_report(grade=);
   TITLE "[미니실습2] &grade 등급 보고서";
   PROC PRINT DATA = shop.users (OBS=10) NOOBS;
      WHERE vip_grade = "&grade";
      VAR user_id name total_spent;
   RUN;
   TITLE;
%MEND vip_report;

%vip_report(grade=gold)
%vip_report(grade=silver)


/* ##########################################################################
   ## SESSION 3 — %DO · %IF (50분)
   ##                슬라이드 14~18 · %DO · %SCAN · %IF · %DO %WHILE
   ########################################################################## */

/* ── S3.1  %DO 기본 — 채널 배열 반복 ──────────────── */
%LET channels = organic paid_search social referral email other;

%MACRO loop_channels;
   %DO i = 1 %TO 6;
      %LET ch = %SCAN(&channels, &i);
      %PUT [&i] &ch;
      %ch_kpi(ch=&ch);
   %END;
%MEND loop_channels;

%loop_channels;


/* ── S3.2  %IF — 매크로 조건 분기 ─────────────────── */
%MACRO smart_kpi(ch=);
   %IF &ch = paid_search OR &ch = email %THEN %DO;
      TITLE "[광고] &ch — ROI 분석";
      PROC SQL;
         SELECT SUM(total_amount) AS sales FORMAT=COMMA15.
         FROM shop.orders
         WHERE channel = "&ch" AND status = 'paid';
      QUIT;
      TITLE;
   %END;
   %ELSE %DO;
      TITLE "[자연] &ch — 일반 KPI";
      PROC FREQ DATA=shop.users;
         WHERE channel = "&ch";
         TABLES vip_grade / NOCUM;
      RUN;
      TITLE;
   %END;
%MEND smart_kpi;

%smart_kpi(ch=organic);     /* 자연 */
%smart_kpi(ch=paid_search); /* 광고 */
%smart_kpi(ch=email);       /* 광고 */


/* ── S3.3  %DO %WHILE / %DO %UNTIL — 조건 반복 ───── */
%MACRO countdown;
   %LET n = 5;
   %DO %WHILE (&n > 0);
      %PUT 카운트 &n;
      %LET n = %EVAL(&n - 1);
   %END;
   %PUT 발사!;
%MEND countdown;

%countdown;


/* ── S3.4  ★ 미니 실습 3 — %DO 12개월 매출 합계 자동 (10분) ── */
/* [목표] %MACRO + %DO 1~12 로 월별 매출 합계 12번 출력
   [산출물] 12개월 매출 보고서 (한 번 호출)                */
%MACRO sum_by_month(year=2024);
   %DO m = 1 %TO 12;
      %LET m2 = %SYSFUNC(PUTN(&m, z2.));
      TITLE "[미니실습3] &year.&m2 월 매출 합계";
      PROC SQL;
         SELECT SUM(total_amount) AS 월매출 FORMAT=COMMA15.
         FROM shop.orders
         WHERE PUT(order_date, YYMMN6.) = "&year.&m2";
      QUIT;
      TITLE;
   %END;
%MEND sum_by_month;

%sum_by_month(year=2024)


/* ##########################################################################
   ## SESSION 4 — INTO :변수 (50분)
   ##                슬라이드 19~23 · INTO · SEPARATED BY · 동적 매크로
   ########################################################################## */

/* ── S4.1  INTO :변수 — 단일 값 저장 ─────────────── */
PROC SQL NOPRINT;
   SELECT COUNT(*)         INTO :n_users     FROM shop.users;
   SELECT MAX(total_amount) INTO :max_amt     FROM shop.orders WHERE status='paid';
   SELECT PUT(AVG(total_amount), COMMA10.) INTO :avg_amt
      FROM shop.orders WHERE status='paid';
QUIT;

%PUT n_users = &n_users;
%PUT max_amt = &max_amt;
%PUT avg_amt = &avg_amt;


/* ── S4.2  INTO :변수 SEPARATED BY — 여러 값 ───── */
PROC SQL NOPRINT;
   SELECT DISTINCT channel
   INTO :ch_list SEPARATED BY ' '
   FROM shop.users;

   SELECT COUNT(DISTINCT channel) INTO :n_ch
   FROM shop.users;
QUIT;

%PUT ch_list = &ch_list (&n_ch 개);


/* ── S4.3  INTO :var1-:varN — 인덱스 변수 ──────── */
PROC SQL NOPRINT;
   SELECT vip_grade, COUNT(*) FORMAT=COMMA10.
   INTO :vip1-:vip5, :cnt1-:cnt5
   FROM shop.users
   WHERE vip_grade IS NOT NULL
   GROUP BY vip_grade;
QUIT;

%PUT vip1=&vip1 cnt1=&cnt1;
%PUT vip2=&vip2 cnt2=&cnt2;
%PUT vip3=&vip3 cnt3=&cnt3;


/* ── S4.4  완전 자동화 매크로 — 채널 자동 반복 ──── */
proc sql;
	select distinct channel into :ch_list separated by ' '
	from shop.users;
quit;

%PUT ch_list : &ch_list;   /* 1. 전체 채널 목록 */

%MACRO auto_all_channels;
   /* 1. ch_list의 개수를 자동으로 산출 */
   %LOCAL n_ch i ch;
   %LET n_ch = %SYSFUNC(countw(&ch_list));

   /* 2. 자동 계산된 n_ch 만큼 루프 실행 */
   %DO i = 1 %TO &n_ch;
      %LET ch = %SCAN(&ch_list, &i);
      %PUT [동적 [&i/&n_ch]] &ch;
      %ch_kpi(ch=&ch);
   %END;
%MEND auto_all_channels;

%auto_all_channels;

/* ── S4.4-확장  VIP 등급 동적 추출 + 자동 반복 (Session 6 daily_full_report 에서 재사용) ── */
/* ====================================================
   VIP 등급 동적 추출 + 자동 반복 KPI 집계
   결과 테이블: shop.kpi_channel_v6
==================================================== */

/* 1. VIP 등급 동적 추출 */
PROC SQL NOPRINT;
   SELECT DISTINCT vip_grade
   INTO :vip_grades SEPARATED BY ' '
   FROM shop.users
   WHERE vip_grade IS NOT NULL;
QUIT;

%PUT NOTE: vip_grades = &vip_grades;

/* 2. 등급 1개에 대한 KPI 계산 + 저장 매크로 */
%MACRO vip_kpi(grade=, first=);

   PROC SQL;
      CREATE TABLE work._tmp_vip_kpi AS
      SELECT "&grade" AS vip_grade LENGTH=20,
             COUNT(*)                   AS order_cnt,
             COUNT(DISTINCT o.user_id)  AS user_cnt,
             SUM(o.total_amount)        AS total_amt,
             AVG(o.total_amount)        AS avg_amt
      FROM shop.orders AS o
      INNER JOIN shop.users AS u
         ON o.user_id = u.user_id
      WHERE u.vip_grade = "&grade";
   QUIT;

   %IF &first = Y %THEN %DO;
      PROC SQL;
         CREATE TABLE shop.kpi_channel_v6 AS
         SELECT * FROM work._tmp_vip_kpi;
      QUIT;
   %END;
   %ELSE %DO;
      PROC APPEND BASE=shop.kpi_channel_v6
                  DATA=work._tmp_vip_kpi FORCE;
      RUN;
   %END;

%MEND vip_kpi;

/* 3. 전체 등급 자동 반복 매크로 */
%MACRO auto_all_vip;
   %LOCAL i g n_ch flag;
   %LET n_ch = %SYSFUNC(COUNTW(&vip_grades));

   %DO i = 1 %TO &n_ch;
      %LET g = %SCAN(&vip_grades, &i);
      %IF &i = 1 %THEN %LET flag = Y;
      %ELSE %LET flag = N;
      %vip_kpi(grade=&g, first=&flag);
   %END;

   %PUT NOTE: 총 &n_ch 개 VIP 등급 KPI가 shop.kpi_channel_v6 에 누적되었습니다.;
%MEND auto_all_vip;

/* 4. 실행 */
%auto_all_vip;

/* 5. 결과 확인 */
PROC PRINT DATA=shop.kpi_channel_v6 NOOBS;
RUN;


/* ── S4.5  ★ 미니 실습 4 — VIP 사용자 ID 동적 IN 절 (10분) ── */
/* [목표] VIP 사용자 ID 를 INTO 로 매크로 변수에 저장 후 IN 절 사용
   [산출물] &vip_list + 동적 분석 결과                      */
PROC SQL NOPRINT;
   SELECT user_id INTO :vip_list SEPARATED BY ','
   FROM shop.users
   WHERE vip_grade = 'gold';
QUIT;
%PUT VIP 수: &SQLOBS;

TITLE "[미니실습4] VIP 고객 주문 내역 (동적 IN 절)";
PROC SQL;
   SELECT * FROM shop.orders
   WHERE user_id IN (&vip_list);
QUIT;
TITLE;


/* ##########################################################################
   ## SESSION 5 — ODS PDF (50분)
   ##                슬라이드 24~28 · ODS PDF · STYLE · STARTPAGE · 한글
   ########################################################################## */

%LET TODAY = %SYSFUNC(TODAY(), YYMMDDN8.);
%LET OUT = /home/student;

/* ── S5.1  ODS PDF — 가장 인기 출력 형식 ────────── */
ODS PDF FILE="&OUT/m4d5_basic_&TODAY..pdf";
TITLE "[S5.1] 기본 PDF 출력";
PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;
ODS PDF CLOSE;


/* ── S5.2  ODS PDF — STYLE 옵션 ────────────────── */
ODS PDF FILE="&OUT/m4d5_journal_&TODAY..pdf"
        STYLE=JOURNAL              /* 학술지 흑백 스타일 */
        STARTPAGE=NO;              /* 한 페이지에 여러 PROC */
ODS NOPROCTITLE;

TITLE "[S5.2] STYLE=JOURNAL · STARTPAGE=NO";

PROC MEANS DATA=shop.users N MEAN STD MEDIAN MAXDEC=1;
   VAR age total_spent;
RUN;

PROC FREQ DATA=shop.users;
   TABLES vip_grade / NOCUM NOPERCENT;
RUN;

PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;

TITLE;
ODS PDF CLOSE;


/* ── S5.3  한글 PDF — 깨짐 방지 ─────────────────── */
OPTIONS LOCALE=KO_KR;

ODS PDF FILE="&OUT/m4d5_korean_&TODAY..pdf"
        STYLE=JOURNAL
        STARTPAGE=NO;

TITLE  "한글 PDF 보고서";
TITLE2 "&SYSDATE — &SYSUSERID";

PROC PRINT DATA=shop.users (OBS=10) NOOBS LABEL;
   VAR user_id name age channel vip_grade total_spent;
   LABEL user_id='고객ID' name='이름' age='나이'
         channel='유입채널' vip_grade='VIP등급' total_spent='누적매출';
RUN;

TITLE; TITLE2;
ODS PDF CLOSE;
OPTIONS LOCALE=EN_US;


/* ── S5.4  ★ 미니 실습 5 — 일간 보고서 자동 (10분) ── */
ODS PDF FILE="&OUT/daily_&TODAY..pdf"
        STYLE=JOURNAL
        STARTPAGE=NO;
ODS NOPROCTITLE;

TITLE  "일간 KPI 보고서";
TITLE2 "&SYSDATE  분석자: &SYSUSERID";

PROC MEANS DATA=shop.users N MEAN STD MAXDEC=1;
   VAR age;
RUN;

PROC FREQ DATA=shop.users;
   TABLES channel / NOCUM;
RUN;

PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;

TITLE; TITLE2;
ODS PDF CLOSE;


/* ##########################################################################
   ## SESSION 6 — ODS EXCEL (50분)
   ##                슬라이드 29~33 · ODS EXCEL · 시트별 · 차트 + 표
   ########################################################################## */

/* ── S6.1  ODS EXCEL 기본 ──────────────────────── */
ODS EXCEL FILE="&OUT/m4d5_basic_&TODAY..xlsx"
          OPTIONS(EMBEDDED_TITLES="YES");

TITLE "[S6.1] 기본 Excel 출력";
PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;

ODS EXCEL CLOSE;


/* ── S6.2  ODS EXCEL — 시트별 자동 정리 ──────── */
ODS EXCEL FILE="&OUT/m4d5_multisheet_&TODAY..xlsx"
          OPTIONS(EMBEDDED_TITLES="YES");

ODS EXCEL OPTIONS(SHEET_NAME="채널KPI");
TITLE "채널별 KPI";
PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;

ODS EXCEL OPTIONS(SHEET_NAME="VIP등급");
TITLE "VIP 등급별";
PROC FREQ DATA=shop.users;
   TABLES vip_grade / NOCUM;
RUN;

ODS EXCEL OPTIONS(SHEET_NAME="결제수단");
TITLE "결제수단 분포";
PROC FREQ DATA=shop.orders;
   TABLES payment_method / NOCUM;
RUN;

TITLE;
ODS EXCEL CLOSE;


/* ── S6.3  ODS EXCEL — 매크로로 채널별 시트 ──── */
ODS EXCEL FILE="&OUT/kpi_&TODAY..xlsx"
          OPTIONS(EMBEDDED_TITLES="YES");

%MACRO excel_per_channel;
   %DO i = 1 %TO &n_ch;
      %LET ch = %SCAN(&ch_list, &i);
      ODS EXCEL OPTIONS(SHEET_NAME="&ch");
      TITLE "&ch 채널 상세";
      PROC SQL OUTOBS=20;
         SELECT user_id, name, age, total_spent, vip_grade
         FROM shop.users
         WHERE channel = "&ch"
         ORDER BY total_spent DESC;
      QUIT;
   %END;
%MEND excel_per_channel;

%excel_per_channel;

TITLE;
ODS EXCEL CLOSE;


/* ── S6.4  종합 매크로 — 일간 자동 보고서 (★ 최종) ─── */
%MACRO daily_full_report;
   %LET td = %SYSFUNC(TODAY(), YYMMDDN8.);

   OPTIONS LOCALE=KO_KR;
   ODS PDF FILE="&OUT/daily_full_&td..pdf"
           STYLE=JOURNAL STARTPAGE=NO;
   ODS NOPROCTITLE;

   TITLE  "일간 종합 보고서 (&td)";
   TITLE2 "분석자: &SYSUSERID";

   /* 1) 전체 기술통계 */
   TITLE3 "1. 전체 사용자 통계";
   PROC MEANS DATA=shop.users N MEAN STD MAXDEC=1;
      VAR age total_spent;
   RUN;

   /* 2) 채널별 KPI */
   TITLE3 "2. 채널별 KPI";
   PROC PRINT DATA=shop.kpi_channel_v6 NOOBS; RUN;

   /* 3) VIP 등급별 (매크로 반복) */
   %DO i = 1 %TO &n_vip;
      %LET g = %SCAN(&vip_grades, &i);
      TITLE3 "3-&i. &g 등급";
      PROC SQL;
         SELECT COUNT(*) AS n, AVG(total_spent) AS avg_spent FORMAT=COMMA12.
         FROM shop.users WHERE vip_grade = "&g";
      QUIT;
   %END;

   TITLE; TITLE2; TITLE3;
   ODS PDF CLOSE;
   OPTIONS LOCALE=EN_US;
%MEND daily_full_report;

%daily_full_report;


/* ── S6.5  ★ 미니 실습 6 — ODS EXCEL 시트 분리 (10분) ─── */
/* [목표] %DO 로 5개 vip_grade 시트 자동 생성 (AUTOFILTER + TAB_COLOR)
   [산출물] 등급별_고객.xlsx (5 시트)                        */
ODS EXCEL FILE="&OUT/등급별_고객_&TODAY..xlsx"
          OPTIONS(EMBEDDED_TITLES="YES");

%MACRO grade_excel;
   %DO i = 1 %TO 5;
      %LET g = %SCAN(vip platinum gold silver bronze, &i);
      ODS EXCEL OPTIONS(SHEET_NAME="&g" AUTOFILTER="ALL");
      TITLE "&g 등급 고객";
      PROC PRINT DATA = shop.users NOOBS;
         WHERE vip_grade = "&g";
         VAR user_id name age total_spent;
      RUN;
   %END;
%MEND grade_excel;

%grade_excel

TITLE;
ODS EXCEL CLOSE;


/* ##########################################################################
   ## SESSION 7 — 실습 5 문항 + D6 예고 (20분)
   ##                실습 1~5 (S1~S6 통합 활용)
   ########################################################################## */

/* ── S7.1  종합 1 - %LET 동적 파일명 (Session 1 복습) ─────── */
%LET YYYYMM = 202611;
%LET CUTOFF = 100000;
ODS PDF FILE="&OUT/&YYYYMM._매출.pdf";
PROC PRINT DATA = shop.orders;
   WHERE PUT(order_date, YYMMN6.) = "&YYYYMM"
     AND total_amount >= &CUTOFF;
RUN;
ODS PDF CLOSE;


/* ── S7.2  종합 2 - %MACRO 5 CSV 자동 적재 (Session 2 복습) ── */
%LET CSV_DIR = /home/student/shop_db;
%MACRO import_csv(name=);
   PROC IMPORT DATAFILE="&CSV_DIR/&name..csv"
               OUT=shop.&name DBMS=CSV REPLACE;
      GETNAMES=YES;
   RUN;
%MEND import_csv;

%import_csv(name=users)
%import_csv(name=orders)
%import_csv(name=products)
%import_csv(name=order_items)
%import_csv(name=categories)


/* ── S7.3  종합 3 - %DO 12 개월 PDF 자동 반복 (Session 3 복습) ── */
%MACRO yearly_pdf(year=);
   %DO m = 1 %TO 12;
      %LET m2 = %SYSFUNC(PUTN(&m, z2.));
      %LET ym = &year.&m2;
      ODS PDF FILE="&OUT/&ym._매출.pdf";
      PROC PRINT DATA = shop.orders;
         WHERE PUT(order_date, YYMMN6.) = "&ym";
      RUN;
      ODS PDF CLOSE;
   %END;
%MEND yearly_pdf;

%yearly_pdf(year=2024)


/* ── S7.4  종합 4 - INTO 동적 IN 절 (Session 4 복습) ─────── */
PROC SQL NOPRINT;
   SELECT user_id INTO :vip_list SEPARATED BY ','
   FROM shop.users WHERE vip_grade = 'vip';
QUIT;
%PUT VIP 수: &SQLOBS;

PROC SQL;
   SELECT * FROM shop.orders WHERE user_id IN (&vip_list);
QUIT;


/* ── S7.5  종합 5 - ODS EXCEL 5 시트 자동 분리 (Session 6 복습) ── */
ODS EXCEL FILE="&OUT/등급별_&TODAY..xlsx";
%MACRO grade_excel2;
   %DO i = 1 %TO 5;
      %LET g = %SCAN(vip platinum gold silver bronze, &i);
      ODS EXCEL OPTIONS(SHEET_NAME="&g" AUTOFILTER="ALL");
      PROC PRINT DATA = shop.users;
         WHERE vip_grade = "&g";
      RUN;
   %END;
%MEND grade_excel2;
%grade_excel2
ODS EXCEL CLOSE;


%PUT ===========================================;
%PUT [M4 D5 완료] 매크로 + ODS 자동화 + 실습 5;
%PUT   1. %LET             - 매크로 변수;
%PUT   2. %MACRO           - 함수 + 매개변수;
%PUT   3. %DO + %IF        - 반복 + 조건;
%PUT   4. INTO :변수       - 동적 매크로;
%PUT   5. ODS PDF          - 보고서 자동 (한글);
%PUT   6. ODS EXCEL        - 시트별 자동;
%PUT ===========================================;
%PUT 내일 D6 : SAS Viya CAS 입문 — 인메모리 분석;
%PUT ===========================================;


/* ==========================================================================
   체크리스트 (강사용)
   --------------------------------------------------------------------------
   ✓ S1  %LET + 시스템 매크로 변수 — TARGET/MIN_AMT 패라미터
   ✓ S2  %MACRO + 매개변수 — ch_kpi · vip_kpi · 기본값
   ✓ S3  %DO · %IF · %WHILE — 채널 반복 · 광고/자연 분기
   ✓ S4  INTO — 채널/VIP 동적 추출 + 자동 반복
   ✓ S5  ODS PDF — JOURNAL · STARTPAGE=NO · 한글
   ✓ S6  ODS EXCEL — 시트별 + 종합 매크로 (daily_full_report)
   ✓ S7  정리 + D6 예고
   ========================================================================== */
