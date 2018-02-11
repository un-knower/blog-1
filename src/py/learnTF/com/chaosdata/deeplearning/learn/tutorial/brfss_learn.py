# coding=utf-8
import feather
import pandavro as pdx

import project_infos

import numpy as np

# import os

# print(os.path.abspath('brfss.py'))
# pip3 install -U pandas

# DATASET:https://www.cdc.gov/brfss/annual_data/2015/files/LLCP2015ASC.zip

# df = brfss.ReadBrfss(filename=project_infos.project_dir + '/data/dataset/LLCP2015ASC.zip')

# df = pandas.read_pickle(path=project_infos.project_dir + '/data/dataset/LLCP2015.pickle')

"""
pip3 install -U feather-format
"""
# df = feather.read_dataframe(source=project_infos.project_dir + '/data/dataset/LLCP2015.feather')

df = pdx.from_avro(project_infos.project_dir + '/data/dataset/LLCP2015.avro')

# df.to_pickle(path=project_infos.project_dir + '/data/dataset/LLCP2015.pickle')

# feather.write_dataframe(df=df, dest=project_infos.project_dir + '/data/dataset/LLCP2015.feather')

"""
ImportError: No module named 'openpyxl'
pip3 install -U openpyxl
"""
# df.to_excel(project_infos.project_dir + '/data/dataset/LLCP2015.xlsx', index=False)

"""
pip3 install -U pandavro
"""
#pdx.to_avro(project_infos.project_dir + '/data/dataset/LLCP2015.avro', df)

print(df.ftypes)

print(df.dtypes)

print(df.head(10))

# df_next = df.astype({'sex': np.bool, 'exercise': np.bool, 'fruit': np.bool, 'vegetable': np.bool})

# pdx.to_avro(project_infos.project_dir + '/data/dataset/LLCP2015.avro', df_next)

# print(df_next.ftypes)
#
# print(df_next.dtypes)
#
# print(df_next.head())
#
# df_part = df_next[['sex', 'age', 'income', 'bmi', 'height', 'weight']]

# df_head = df_part.head()

# print(df_head)
