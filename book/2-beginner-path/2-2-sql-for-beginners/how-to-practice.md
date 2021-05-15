# How to practice SQL with this book

For the best experience of readers I prepared a small database and tutorial that will explain how you can use it while studying.

All queries I show in [SQL for beginners](sql-1.md) chapter are real. It means that you can run them yourself using provided database.

> The data is fake. At the end of the tutorial I put a generation script.

To connect to that database I recommend using a real IDE tool called DBeaver.

This tutorial consists of two parts:
1. installing needed software on your computer
2. download and connect to the database

# Install DBeaver

DBeaver is an open-source tool to connect to databases and write SQL queries.

1. Go to https://dbeaver.io/download/ and download a Community Edition version for your system (Windows, macOS or Linux)
2. Install it (usually by double clicking on the downloaded file)
3. Upon first launch it will ask if you want to create a sample database. Click "Yes" to that
4. On the left sidebar click on the database "DBeaver Sample Database", it will ask you to download needed drivers. Click "Download"
5. Right-click on the sample database "SQL editor" -> "Open SQL script" and you will see a window where you can write SQL queries

From now on you have a sample database and you can use it!

<img src="img/dbeaver.png" alt="DBeaver window">

(final look may be a bit different in your operation system)

# Connecting a database from this book

Specifically for this book I've prepared a small database which you can download and connect to DBeaver. I used SQLite database, it is a super simple and embeddable database, doesn't require from you to install the database server and configure it.

1. Download a [file with data](./assets/db.sqlite)
1. In DBeaver menu click "Database" -> "New database connection"
1. Select SQLite type and click "Next"
1. Click "Browse" and select a path to the downloaded database
1. Click "Finish"

Congrats! Now you have the same datasource and you can run queries from this book.

# How I generated fake data

For the future reference here is a Python script which generates SQLite database:

```python
from faker import Faker
import numpy as np
import pandas as pd
import sqlite3


fake = Faker()

Faker.seed(42)
np.random.seed(42)

NUM_RECORDS = 10000

def generate_user(i):
    f_name = fake.first_name()
    l_name = fake.last_name()
    email = (
        f_name.lower() 
        + "."
        + l_name.lower() 
        + fake.year()[2:]
        + "@" 
        + fake.free_email_domain()
    )
    percent_of_empty_values = 0.05
    return {
        "id": i + 1,
        "first_name": f_name,
        "last_name": l_name if np.random.rand() < 1 - percent_of_empty_values else np.nan,
        "email": email,
        "reg_date": fake.date_time_between(start_date='-5y'),
        "country": fake.country(),
    }

users = [generate_user(i) for i in range(NUM_RECORDS)]

df_users = pd.DataFrame(users)

Faker.seed(42)
np.random.seed(42)

class MyProvider():
    
    @staticmethod
    def random_price():
        prices = [29.99, 59.99, 99.99]
        return np.random.choice(prices)
    
    @staticmethod
    def random_currency():
        currencies = ['USD', 'EUR']
        return np.random.choice(currencies)

    @staticmethod
    def random_user_id():
        users = np.arange(1, NUM_RECORDS + 1)
        return np.random.choice(users)
    
    @staticmethod
    def random_tax():
        taxes = [0.18, 0.32]
        return np.random.choice(taxes)

    
def generate_payment(i):
    return {
        "id": i + 1,
        "event_date": fake.date_time_between(start_date='-3y'),
        "gross_revenue": MyProvider.random_price(),
        "currency": MyProvider.random_currency(),
        "user_id": MyProvider.random_user_id(),
        "tax_rate": MyProvider.random_tax(),
    }

payments = [generate_payment(i) for i in range(int(NUM_RECORDS * 0.099))]

df_payments = pd.DataFrame(payments)



with sqlite3.connect('db.sqlite') as conn:
    cur = conn.cursor()
    cur.execute("drop table if exists users")
    cur.execute("drop table if exists payments")
    df_users.to_sql('users', con=conn, index=False)
    df_payments.to_sql('payments', con=conn, index=False)
    cur.execute("select * from users").fetchone()
    cur.execute("select * from payments").fetchone()
```
