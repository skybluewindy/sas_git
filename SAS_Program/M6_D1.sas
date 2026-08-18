/*ML Day1~Day8 */
LIBNAME shop "/home/student/shop_db";

proc import datafile="/home/student/m6_data/users.csv"
	out= shop.users
	dbms= csv replace;
	getnames=yes;
	guessingrows=max;
run;

/*데이터 분포 확인*/
proc contents data=shop.users
	varnum;
run;

/*[STEP 1] churn 비율 확인*/
PROC FREQ DATA=shop.users;
TABLES churn / NOCUM;
RUN;

/* users > churn 기준으로 sort */
proc sort data=shop.users
	out = users_sorted;
	by chrun;
Run;


/* [STEP 2] 60/40 분할  */
/* (churn 비율 유지, Stratified) */
PROC SORT DATA=shop.users
OUT=work.users_sorted;
BY churn; /* Stratify 기준 */
RUN;

PROC SURVEYSELECT DATA=work.users_sorted
OUT=work.split
SAMPRATE=0.60 /* 60% Train */
SEED=42 /* 재현성 */
OUTALL; /* 전체 출력 */
STRATA churn; /* Stratified */
RUN;


/*  train -> selected 1, 0 이면 test*/
DATA train.test;
	SET work.split;
	IF Selected=1 THEN OUTPUT work.train;
	ELSE OUTPUT work.test;
RUN;



/* [STEP 4] 결과 확인 - 분할 결과 비율 검증 */
/* data 검증 > train , test */
PROC FREQ DATA=train;
TABLES churn / NOCUM;
RUN;

PROC FREQ DATA=test;
TABLES churn / NOCUM;
RUN;

proc import data= shop.users
		outfile = "/home/student/m6_data/users_copy"
		dbms=csv replace;
run;


proc python;
submit:
print("Hello from SAS Python !!")
print("머신러닝 start")

a = 100
b = 200
print(f' {a} + {b} = {a+b}')
endsubmit;
quit;

proc python;
submit;
# users.csv file read
# 데이터 관측
import pandas as pd
df = pd.read_csv("/home/student/m6_data/users.csv")
print(f"행수 : {df.shape[0])}, 컬럼수 : {df.shape[1]}, \n 컬럼 목록: {list(df.columns)}")

print()
# 첫 5행 보기
print(df.head())

endsubmit;

quit;

PROC PYTHON;
SUBMIT;
import sys
import pandas as pd
import numpy as np
import sklearn
print('=' * 50)
print(f'Python 버전 : {sys.version.split()[0]}')
print(f'pandas : {pd.__version__}')
print(f'numpy : {np.__version__}')
print(f'scikit
-learn : {sklearn.__version__}')
print('=' * 50)
ENDSUBMIT;

/* python에서 vip 숫자와 vip 비율 계산 */
proc python;
submit;
import pandas as pd

# sas macro -> python : SAS.symget
vip_spent = SAS.symget('vip_spent')
vip_orders = SAS.symget('CSV_DIR') + 'users.csv'
df = pd.read_csv(file_path)
QUIT;
/* 기대 결과 */
/* Python 버전 : 3.9.x */
/* pandas : 1.x.x */
/* numpy : 1.x.x */
/* scikit
-learn : 1.x.x */
/* 잘 안 될 때에는 버전을 업그레이드 해줘야 함*/

/* SAS 에서 임계값 정의 */
%LET vip_threshold = 100000; /* VIP 기준 매출 */
%LET min_age = 18; /* 최소 연령 */
%let CSV_DIR = /home/student/m6_data;
/* Python 에서 매크로 변수 사용 */

PROC PYTHON;
SUBMIT;
import pandas as pd

# ★ SAS → Python (symget)
vip_threshold = float(SAS.symget('vip_threshold'))
min_age = int(SAS.symget('min_age'))

path = SAS.symget('CSV_DIR') + '/users.csv'
print(f"path : ,{path} ")
df = pd.read_csv(path)
#df = pd.read_csv('/home/student/m6_data/users.csv')
vip = df[(df.age >= min_age) & (df.total_spent >= vip_threshold)]
vip_count = len(vip)
vip_pct = vip_count / len(df) * 100

#★ Python → SAS (symput)
SAS.symput('vip_count', str(vip_count))
SAS.symput('vip_pct', f'{vip_pct:.2f}')
ENDSUBMIT;
QUIT;

/* SAS 에서 Python 결과 사용 */
%PUT VIP 고객 수: &vip_count;
%PUT VIP 비율: &vip_pct%;


/* STEP 1: SAS 데이터 → CSV */
PROC EXPORT DATA=shop.users(KEEP=user_id channel age total_spent churn)
OUTFILE='&CSV_DIR/users_churn.csv' DBMS=CSV REPLACE;
RUN;

/* STEP 2: Python 으로 채널별 통계 계산 */
PROC PYTHON;
SUBMIT;
import pandas as pd

file_path = SAS.symget('CSV_DIR') + '/users_chrun.csv'
df = pd.read_csv('file_path')

# 채널별 집계 (회원 수, 평균 매출, 이탈률 작성)
stats = df.groupby('channel').agg(nusers=('user_id', 'count'),
avg_spent=('total_spent', 'mean'),
churn_rate=('churn', 'mean')
).round(2)
print(f'stats :{stats}')
print(stats)
save_path = SAS.symget('CSV_DIR') + '/churn_stats.csv'
stats.to_csv(save_path)


ENDSUBMIT;
QUIT;

%put &CSV_DIR;
proc import datafile = "&CSV_DIR/churn_stats.csv" out=stats dbms=csv replace;
run;
proc print data=stats; run;


/* vip 기준 20만 이상, 주문 10건 이상*/
%let vip_spent = 200000;
%let vip_orders 10;

/* python에서 vip 숫자와 vip 비율 계산*/
PROC PYTHON;
SUBMIT;
import pandas as pd

# 1. SAS macro -> python : symget 후 숫자형 변환 (float 또는 int)
vip_spent = float(SAS.symget('vip_spent'))
vip_orders = int(SAS.symget('vip_orders'))
file_path = SAS.symget('CSV_DIR') + '/users.csv'

df = pd.read_csv(file_path)

if 'order_count' not in df.columns:
    df['order_count'] = 0

# 2. and 대신 & 사용 및 각 조건 괄호 필수
vip = df[(df.total_spent >= vip_spent) & (df.order_count >= vip_orders)]
print(vip.head())

print(f'전체 회원수 : {len(df)}')
print(f'VIP 회원수 : {len(vip)} 비율 : {len(vip)/len(df) if len(df) > 0 else 0}')
quit;



# 3. python 변수 -> sas macro 변수로
SAS.symput('vip_n', str(len(vip)))
SAS.symput('vip_rate', f'{(len(vip)/len(df)):.4f}' if len(df) > 0 else '0')

ENDSUBMIT;
QUIT;

%PUT VIP 회원수 : &vip_n.;
%PUT VIP 비율 : &vip_rate.;

PROC PYTHON;
SUBMIT;
import pandas as pd
df = pd.read_csv(f"{SAS.sysget('CSV_DIR')}/users.csv")
# [1] 데이터 크기
print(f'행 수: {df.shape[0]:,} / 컬럼 수: {df.shape[1]}')
# [2] 결측치 확인
print('결측치 비율:')
print(df.isnull().mean().sort_values(ascending=False).head())

# [3] 수치 변수 요약
print(df[['age', 'total_spent', 'order_count', 'recency']].describe())

# [4] 범주 변수 분포
print('채널별 분포:')
print(df.channel.value_counts(normalize=True).round(3))
# [5] 이탈률(타겟 변수)
print(f'이탈률: {df.churn.mean():.2%}')
# [6] 이상치 진단 - IQR
Q1, Q3 = df.total_spent.quantile([0.25, 0.75])
upper = Q3 + 1.5 * (Q3 - Q1)
outliers = df[df.total_spent > upper]
print(f'이상치: {len(outliers):,} ({len(outliers)/len(df):.1%})')
ENDSUBMIT;
QUIT;