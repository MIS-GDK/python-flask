import os
from flask import Flask


def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    app.config.from_mapping(
        SECRET_KEY="dev",
        # DATABASE=os.path.join(app.instance_path, "flaskr.sqlite")
    )

    if test_config is None:
        # load the  config, if it exists, when not testing
        app.config.from_pyfile("config.py", silent=True)
    else:
        # load the test config if passed in
        app.config.update(test_config)
    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass
        # a simple page that says hello

    @app.route("/")
    @app.route("/hello")
    def hello():
        return "Hello, World!"

    from . import db

    db.init_app(app)
    # 使用 app.register_blueprint() 导入并注册 蓝图。新的代码放在工厂函数的尾部返回应用之前。
    from . import auth

    app.register_blueprint(auth.bp)

    return app


# with open(r"gdk.txt", mode="wt") as f:
#     f.write(__name__)
#     f.write(os.getcwd())
