from sqlalchemy import create_engine, MetaData
import os, sys, pathlib

from db import user, post

from flaskr.settings import BASE_DIR, get_config

DSN = "postgresql://{user}:{password}@{host}:{port}/{database}"

ADMIN_DB_URL = DSN.format(
    user="postgres",
    password="414214",
    database="postgres",
    host="localhost",
    port=5432,
)

admin_engine = create_engine(ADMIN_DB_URL, isolation_level="AUTOCOMMIT")

USER_CONFIG_PATH = BASE_DIR / "config" / "polls.yaml"
TEST_USER_CONFIG_PATH = BASE_DIR / "config" / "polls_test.yaml"
print(USER_CONFIG_PATH)

USER_CONFIG = get_config(USER_CONFIG_PATH)
TEST_CONFIG = get_config(TEST_USER_CONFIG_PATH)

USER_DB_URL = DSN.format(**USER_CONFIG["postgres"])
TEST_DB_URL = DSN.format(**TEST_CONFIG["postgres"])
user_engine = create_engine(USER_DB_URL)
test_engine = create_engine(TEST_DB_URL)


def setup_db(config):

    db_name = config["database"]
    db_user = config["user"]
    db_pass = config["password"]

    conn = admin_engine.connect()

    conn.execute("drop database if exists %s" % db_name)
    conn.execute("drop role if exists %s" % db_user)
    conn.execute("create user %s with password '%s'" % (db_user, db_pass))
    conn.execute("create database %s encoding 'utf-8'" % db_name)
    conn.execute("grant all PRIVILEGES on database %s to %s" % (db_name, db_user))

    conn.close()


def teardown_db(config):

    db_name = config["database"]
    db_user = config["user"]

    conn = admin_engine.connect()
    conn.execute(
        """
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '%s'
        AND pid <> pg_backend_pid();"""
        % db_name
    )
    conn.execute("DROP DATABASE IF EXISTS %s" % db_name)
    conn.execute("DROP ROLE IF EXISTS %s" % db_user)
    conn.close()


def create_tables(engine=test_engine):
    meta = MetaData()
    meta.create_all(bind=engine, tables=[user, post])


def drop_tables(engine=test_engine):
    meta = MetaData()
    meta.drop_all(bind=engine, tables=[user, post])


def sample_data(engine=test_engine):
    conn = engine.connect()
    conn.execute(
        user.insert(),
        [
            {"question_text": "今晚吃什么?", "pub_date": "2022-08-08"},
            {"question_text": "服务之星评选?", "pub_date": "2022-08-07"},
        ],
    )
    conn.execute(
        post.insert(),
        [
            {"choice_text": "烧烤", "votes": 0, "question_id": 1},
            {"choice_text": "青海拉面", "votes": 0, "question_id": 1},
            {"choice_text": "公司饭堂", "votes": 0, "question_id": 1},
            {"choice_text": "马志强", "votes": 0, "question_id": 2},
            {"choice_text": "闫静杰", "votes": 0, "question_id": 2},
            {"choice_text": "张欢", "votes": 0, "question_id": 2},
        ],
    )
    conn.close()


if __name__ == "__main__":
    pass
    # print(USER_CONFIG["postgres"])
    setup_db(TEST_CONFIG["postgres"])
    # create_tables(engine=user_engine)
    # sample_data(engine=user_engine)
    # drop_tables(engine=user_engine)
    # teardown_db(USER_CONFIG['postgres'])
