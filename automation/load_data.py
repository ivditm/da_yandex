# импортируем библиотеки
from dotenv import load_dotenv
import os
import pandas as pd
from sqlalchemy import create_engine

load_dotenv()

db_config = {'user': os.getenv('user', ''),
             'pwd': os.getenv('pwd', ''),
             'host': os.getenv('host', ''),
             'port': 6432,
             'db': os.getenv('db', '')}

connection_string = 'postgresql://{}:{}@{}:{}/{}'.format(db_config['user'],
                                                         db_config['pwd'],
                                                         db_config['host'],
                                                         db_config['port'],
                                                         db_config['db'])

engine = create_engine(connection_string)
query = '''select * from dash_visits ;'''
dash_visits = pd.io.sql.read_sql(query, con=engine)
dash_visits.to_csv('dash_visits.csv', sep=',', encoding='utf-8')
