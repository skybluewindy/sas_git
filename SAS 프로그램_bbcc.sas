/* ============================================================================
   m3d1_practice.sas - M3 D1 PROC SQL 기초 - 이론 시연 코드 + 실습 문제 (수강생용)
   ----------------------------------------------------------------------------
   각 Session : 이론 시연 코드(실행 가능) + 실습 문제(문제만 - 코드 작성은 직접)
   ============================================================================ */

LIBNAME shop '/home/student/shop_db';
OPTIONS USER=shop;


/* ── Session 1 - SQL 개요 + DATA Step vs PROC SQL ──────────────────────── */

PROC SQL OUTOBS=10;
   SELECT user_id, name, age, city
   FROM shop.users;
QUIT;


DATA work.seoul_data;
   SET shop.users;
   WHERE city = '서울';
   IF age >= 60 THEN age_group = '시니어';
   ELSE age_group = '청년';
RUN;


PROC SQL OUTOBS=20;
   SELECT user_id, name, age, city,
          CASE WHEN age >= 60 THEN '시니어' ELSE '청년' END AS age_group
   FROM shop.users
   WHERE city = '서울';
QUIT;


PROC SQL OUTOBS=20;
   SELECT user_id, name, age, city
   FROM shop.users
   WHERE city = '서울'
     AND age BETWEEN 30 AND 39;
QUIT;


/* ── 실습 1 - PROC SQL 첫 코드 실행 (문제만) ─────────────────────────────
   사용 테이블 : shop.users (50,000 행)
   추출 컬럼   : user_id, name, age, city, vip_grade
   조건        : Q1) WHERE 없이 처음 20행 조회
                 Q2) WHERE city='서울' 조건 추가 (서울 거주자만)
   기대 결과   : 회원 5 컬럼 20행 (전체 또는 서울)
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 2 - SELECT + Alias + 계산 컬럼 + FORMAT ───────────────────── */

PROC SQL OUTOBS=5;
   SELECT * FROM shop.users;
QUIT;

PROC SQL OUTOBS=5;
   SELECT user_id, name, age, city, vip_grade
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT
      name AS 고객명,
      age AS 나이,
      age * 12 AS 개월수,
      CAT(city, ' ', vip_grade) AS 지역등급,
      vip_grade AS 등급
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT
      UPCASE(payment_method) AS 결제수단,
      ROUND(total_amount, 100) AS 금액반올림 FORMAT=COMMA12.,
      SUBSTR(channel, 1, 3) AS 채널약어,
      total_amount FORMAT=COMMA12. AS 금액
   FROM shop.orders;
QUIT;


PROC SQL;
   SELECT
      COUNT(*) AS 주문수 FORMAT=COMMA12.,
      SUM(total_amount) AS GMV FORMAT=COMMA15.,
      AVG(total_amount) AS AOV FORMAT=COMMA12.,
      CALCULATED GMV / CALCULATED 주문수 AS 재계산AOV FORMAT=COMMA12.
   FROM shop.orders;
QUIT;


/* ── 실습 2 - SELECT 다양한 패턴 (문제만) ────────────────────────────────
   사용 테이블 : shop.products (2,000 행)
   추출 컬럼   : product_id, product_name, price, rating_avg
   조건        : Q1) 전체 컬럼 조회 (SELECT *)
                 Q2) 특정 컬럼만 (4개 컬럼 명시)
                 Q3) AS 별칭 적용 (price → 정가)
   기대 결과   : 상품 컬럼 다양한 형식 (10행)
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 3 - WHERE 절 + NULL 처리 ──────────────────────────────────── */

PROC SQL OUTOBS=10;
   SELECT name, age, city, vip_grade,
          signup_date FORMAT=YYMMDDS10. AS 가입일
   FROM shop.users
   WHERE age BETWEEN 30 AND 50;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, age, city
   FROM shop.users
   WHERE city IN ('서울', '부산', '대구');
QUIT;


PROC SQL OUTOBS=10;
   SELECT name
   FROM shop.users
   WHERE name LIKE '김%';
QUIT;


/*PROC SQL;
   SELECT COUNT(*) FROM shop.users WHERE vip_grade = .;
*/

PROC SQL;
    SELECT COUNT(*) FROM shop.users WHERE vip_grade IS NULL;

   SELECT COUNT(*) AS NULL수
   FROM shop.users WHERE vip_grade IS NULL;

   SELECT COUNT(*) AS 정상수
   FROM shop.users WHERE vip_grade IS NOT NULL;
QUIT;


PROC SQL OUTOBS=30;
   SELECT name, age, city, vip_grade,
          signup_date FORMAT=YYMMDDS10. AS 가입일
   FROM shop.users
   WHERE signup_date BETWEEN '01JAN2025'd AND '31MAR2025'd
     AND city IN ('서울', '부산', '대구')
     AND name LIKE '김%'
     AND vip_grade IS NOT NULL;
QUIT;


/* ── 실습 3 - 복합 조건 추출 (문제만) ─────────────────────────────────────
   사용 테이블 : shop.orders (200,000 행)
   추출 컬럼   : order_id, user_id, total_amount, status, channel
   조건        : status='paid' AND total_amount>=100000
                 AND channel IN ('app','web')
                 주문일 내림차순 Top 20
   기대 결과   : VIP 후보 결제 20건
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 4 - ORDER BY + 다중 정렬 + Top N ──────────────────────────── */

PROC SQL OUTOBS=10;
   SELECT user_id, name, total_spent FORMAT=COMMA15.
   FROM shop.users
   ORDER BY total_spent DESC;
QUIT;


PROC SQL OUTOBS=10;
   SELECT user_id, vip_grade, total_spent FORMAT=COMMA15., order_count
   FROM shop.users
   WHERE vip_grade IS NOT NULL
   ORDER BY vip_grade DESC,
            total_spent DESC,
            order_count DESC;
QUIT;


PROC SQL OUTOBS=10;
   SELECT user_id, name, city, vip_grade,
          total_spent FORMAT=COMMA15.,
          order_count
   FROM shop.users
   ORDER BY total_spent DESC, order_count DESC;
QUIT;


/* ── 실습 4 - 다중 정렬 응용 (문제만) ─────────────────────────────────────
   사용 테이블 : shop.users
   추출 컬럼   : 고객명, 등급, 누적매출
   조건        : 등급(VIP→일반) + 누적매출 내림차순 다중 정렬
                 (같은 등급 안에서는 매출 큰 순), Top 30
   기대 결과   : 등급+매출 정렬된 회원 30명
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 5 - DISTINCT + COUNT(DISTINCT) ────────────────────────────── */

PROC SQL;
   SELECT DISTINCT city
   FROM shop.users
   ORDER BY city;
QUIT;


PROC SQL;
   SELECT DISTINCT city, vip_grade
   FROM shop.users
   WHERE vip_grade IS NOT NULL
   ORDER BY city, vip_grade;
QUIT;


PROC SQL;
   SELECT COUNT(*) AS 전체행수 FORMAT=COMMA12.,
          COUNT(vip_grade) AS NOT_NULL수 FORMAT=COMMA12.,
          COUNT(DISTINCT vip_grade) AS 유니크등급 FORMAT=COMMA12.
   FROM shop.users;
QUIT;


PROC SQL;
   SELECT COUNT(*) AS 전체주문수 FORMAT=COMMA12.,
          COUNT(DISTINCT user_id) AS 고유고객수 FORMAT=COMMA12.,
          CALCULATED 전체주문수 / CALCULATED 고유고객수
             AS 인당주문수 FORMAT=10.2
   FROM shop.orders;
QUIT;


/* ── 실습 5 - DISTINCT 활용 (문제만) ──────────────────────────────────────
   사용 테이블 : shop.users + shop.orders
   추출 컬럼   : DISTINCT 컬럼 / COUNT(DISTINCT ...)
   조건        : Q1) SELECT DISTINCT city → 도시 종류
                 Q2) SELECT DISTINCT channel (shop.orders) → 채널 종류
                 Q3) COUNT(DISTINCT user_id) WHERE status='paid' AS 활동고객
   기대 결과   : 도시 17개 / 채널 4개 / 활동 고객 N명
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 6 - CASE WHEN - 등급 자동 부여 ────────────────────────────── */

PROC SQL OUTOBS=10;
   SELECT name, age,
          CASE WHEN age >= 60 THEN '시니어'
               ELSE '청년'
          END AS 연령대
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, age,
          CASE
             WHEN age < 20 THEN '10대'
             WHEN age < 30 THEN '20대'
             WHEN age < 40 THEN '30대'
             WHEN age < 50 THEN '40대'
             WHEN age < 60 THEN '50대'
             ELSE '시니어'
          END AS 연령대
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, age, total_spent,
          CASE WHEN age >= 60 THEN '시니어'
               WHEN age >= 40 THEN '중장년'
               WHEN age >= 20 THEN '청년'
               ELSE '미성년'
          END AS 연령대,
          CASE WHEN total_spent >= 1000000 THEN 'VIP'
               WHEN total_spent >= 100000 THEN '우수'
               ELSE '일반'
          END AS 금액등급
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=20;
   SELECT user_id, name,
          total_spent FORMAT=COMMA15.,
          CASE
             WHEN total_spent >= 5000000 THEN 'VIP'
             WHEN total_spent >= 1000000 THEN 'General'
             WHEN total_spent >= 100000 THEN 'Casual'
             ELSE 'Inactive'
          END AS 등급
   FROM shop.users
   ORDER BY total_spent DESC;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, channel,
          CASE channel
             WHEN 'paid_search' THEN '검색 광고'
             WHEN 'social' THEN '소셜'
             WHEN 'organic' THEN '오가닉'
             WHEN 'referral' THEN '추천'
             ELSE '기타'
          END AS 채널_한글
   FROM shop.users;
QUIT;


PROC SQL OUTOBS=10;
   SELECT name, vip_grade,
          CASE
             WHEN vip_grade IS NULL THEN '미입력'
             WHEN vip_grade = 'gold' THEN 'VIP'
             ELSE '일반'
          END AS 분류
   FROM shop.users;
QUIT;


/* ── 실습 6 - CASE 활용 종합 (문제만) ─────────────────────────────────────
   사용 테이블 : shop.users
   추출 컬럼   : vip_grade, 연령대 (CASE), COUNT
   조건        : CASE WHEN 으로 연령대 그룹화 (20대/30대/40대/50대+)
                 등급별 통계와 결합 (GROUP BY vip_grade, CALCULATED 연령대)
                 등급 × 연령대 매트릭스
   기대 결과   : 연령대 × 등급 그룹별 회원 수
   ──────────────────────────────────────────────────────────────────── */


/* ── Session 7 - 종합 시연 (CRISP 설계 + 4-EYE 검증) ───────────────────── */

PROC SQL OUTOBS=10;
   SELECT
      name AS 고객명,
      city AS 지역,
      age AS 나이,
      signup_date FORMAT=YYMMDDS10. AS 가입일,
      total_spent AS 누적매출 FORMAT=COMMA15.,
      order_count AS 주문수 FORMAT=COMMA10.,
      CASE
         WHEN total_spent >= 5000000 THEN 'VIP 확정'
         ELSE 'VIP 후보'
      END AS 등급
   FROM shop.users
   WHERE signup_date BETWEEN '01JAN2025'd AND '31MAR2025'd
     AND city IN ('서울', '부산')
     AND age >= 60
     AND total_spent >= 1000000
   ORDER BY total_spent DESC;
QUIT;


PROC SQL;
   SELECT COUNT(*) AS 대상자수
   FROM shop.users
   WHERE signup_date BETWEEN '01JAN2025'd AND '31MAR2025'd
     AND city IN ('서울', '부산')
     AND age >= 60;
QUIT;


PROC SQL;
   SELECT COUNT(*) AS VIP후보수
   FROM shop.users
   WHERE signup_date BETWEEN '01JAN2025'd AND '31MAR2025'd
     AND city IN ('서울', '부산')
     AND age >= 60
     AND total_spent >= 1000000;
QUIT;


/* ── 종합 실습 1/5 - 서울 30~50대 VIP 회원 Top 10 (문제만) ───────────────
   사용 테이블 : shop.users
   추출 컬럼   : user_id, name, age, city, vip_grade, total_spent
   조건        : city='서울' AND age BETWEEN 30 AND 50 AND vip_grade='gold'
                 total_spent DESC 정렬, Top 10
   ──────────────────────────────────────────────────────────────────── */

/* ── 종합 실습 2/5 - 연령대 + 등급 동시 부여 (문제만) ─────────────────────
   사용 테이블 : shop.users
   추출 컬럼   : user_id, name, age, total_spent, 연령대(CASE age), 등급(CASE total_spent)
   조건        : 연령대 = 10대/20대/30대/40대+, 등급 = total_spent>=10,000,000 이면 VIP 아니면 일반
                 WHERE age IS NOT NULL, ORDER BY age, total_spent DESC, Top 30
   ──────────────────────────────────────────────────────────────────── */

/* ── 종합 실습 3/5 - 가입 채널별 회원 수 + 평균 매출 (문제만) ─────────────
   사용 테이블 : shop.users
   추출 컬럼   : channel, COUNT(*) 회원수, COUNT(DISTINCT vip_grade) 등급수, AVG(total_spent) 평균매출
   조건        : WHERE channel IS NOT NULL, GROUP BY channel, ORDER BY 회원수 DESC
   ──────────────────────────────────────────────────────────────────── */

/* ── 종합 실습 4/5 - 결제 정상 주문 + 채널별 정렬 (문제만) ────────────────
   사용 테이블 : shop.orders
   추출 컬럼   : order_id, user_id, order_date, channel, total_amount
   조건        : WHERE status='paid', ORDER BY channel, order_date DESC, Top 30
   ──────────────────────────────────────────────────────────────────── */

/* ── 종합 실습 5/5 - 활성 회원 분류 (문제만) ──────────────────────────────
   사용 테이블 : shop.users
   추출 컬럼   : user_id, name, last_login_date, 활성도(CASE)
   조건        : (TODAY()-last_login_date)<=7 활성 / <=30 보통 / 그외 휴면
                 WHERE last_login_date IS NOT NULL, ORDER BY last_login_date DESC, Top 30
   ──────────────────────────────────────────────────────────────────── */
