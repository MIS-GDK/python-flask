import os, sys, pathlib
from flask import current_app, g
import click
from flask.cli import with_appcontext
import psycopg2

sys.path.append(os.path.abspath(os.path.dirname(os.path.dirname(__file__))))

from flaskr.settings import config
from psycopg2 import extras  # 不能少


from sqlalchemy import MetaData, Table, Column, Integer, Date, String, ForeignKey

DSN = "postgresql://{user}:{password}@{host}:{port}/{database}"
USER_DB_URL = DSN.format(**config["postgres"])


def get_db():
    if "db_cur" not in g:
        # g.db = create_engine(USER_DB_URL).connect()
        conn = psycopg2.connect(
            database=config["postgres"]["database"],
            user=config["postgres"]["user"],
            password=config["postgres"]["password"],
            host=config["postgres"]["host"],
            port=config["postgres"]["port"],
        )
        g.db = conn
        g.db_cur = conn.cursor(cursor_factory=extras.DictCursor)
    # current_app.logger.debug(type(g))
    return (g.db, g.db_cur)


def close_db(e=None):
    db = g.pop("db", None)
    db_cur = g.pop("db_cur", None)
    if db is not None:
        db_cur.close()
        db.close()


def init_db(testflag=None):
    if not testflag:
        db, db_cur = get_db()
        with current_app.open_resource("schema.sql") as f:
            db_cur.execute(f.read().decode("utf-8"))
        db.commit()
    else:
        db, db_cur = get_db()
        with current_app.open_resource("schema_test.sql") as f:
            db_cur.execute(f.read().decode("utf-8"))
        db.commit()


"""
使用Click的command()装饰器添加命令，执行时不会自动推入应用上下文，要想达到同样的效果，增加with_appcontext装饰器
"""


@click.command("init-db")
@with_appcontext
def init_db_command():
    """Clear the existing data and create new tables."""
    init_db()
    click.echo("Initialized the database.")


def init_app(app):
    # app.teardown_appcontext() tells Flask to call that function when cleaning up after returning the response.
    app.teardown_appcontext(close_db)
    # app.cli.add_command() adds a new command that can be called with the flask command.
    app.cli.add_command(init_db_command)


meta = MetaData()

user = Table(
    "user",
    meta,
    Column("id", Integer, primary_key=True),
    Column("username", String(200), nullable=False),
    Column("password", String(200), nullable=False),
)

post = Table(
    "post",
    meta,
    Column("id", Integer, primary_key=True),
    Column("author_id", Integer, ForeignKey("user.id", ondelete="CASCADE")),
    Column("created", Date, nullable=False),
    Column("title", String(500), nullable=False),
    Column("body", String, nullable=False),
)
