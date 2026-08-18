proc python;
submit;
import pandas as pd
from sklearn.model_selection import train_test_split

df = pd.read.csv("/home/student.users.csv")
X = df.drop(columns=['churn','user_id'])
Y = df['churn']

print(df.head())
print(X.head)
print(Y.head)


# 60 :40 train : test 분리
X_tr, X_te, Y_tr, Y_te = train_test_spilt(
X, Y, random_state=42, stratify=Y, train_size=0.6)

print(f'Train	: {len(X_tr):,}) 행 churn 비율 {Y_tr.mean():.3f'}
print(f'Test	: {len(X_te):,}) 행 churn 비율 {Y_te.mean():.3f'}
endsubmit;
quit;