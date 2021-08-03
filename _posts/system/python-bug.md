---
title: "python-bug"
category: "system"
---

### TypeError: ufunc 'isnan' not supported for the input types, and the inputs could not be safely coerced to any supported types according to the casting rule ''safe''
```python
df[column1].apply(lambda x: np.isnan(x))
# df[column1] dtype : object
```
에서 발생한 오류

출처: https://stackoverflow.com/questions/36000993/numpy-isnan-fails-on-an-array-of-floats-from-pandas-dataframe-apply/36001292 
> np.isnan can be applied to NumPy arrays of native dtype (such as np.float64)

> Since you have Pandas, you could use pd.isnull instead -- it can accept NumPy arrays of object or native dtypes

`pd.isnull` 로 적용하여 해결

