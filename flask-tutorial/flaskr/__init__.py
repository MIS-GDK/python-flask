import os
from flask import Flask


def create_app(test_config=None):
    # create and configure the app
    # instance_relative_config=True 告诉应用配置文件是相对于 instance folder 的相对路径。实例文件 夹在 flaskr 包的外面，用于存放本地数据（例如配置密钥和数据 库）
    app = Flask(__name__, instance_relative_config=True)
    # SECRET_KEY 是被 Flask 和扩展用于保证数据安全的。在开发 过程中，为了方便可以设置为 'dev' ，但是在发布的时候应当使用 一个随机值来重载它
    app.config.from_mapping(
        SECRET_KEY="7712a09b74f78bd374ea537faf0fb0b0e8a2e5cb7fa65d42104c8686c6f26aba",
        # DATABASE=os.path.join(app.instance_path, "flaskr.sqlite")
    )

    if test_config is None:
        # load the  config, if it exists, when not testing
        # 使用 config.py 中的值来重载缺省配置，如果 config.py 存在的话。 例如，当正式部署的时候，用于设置一个正式的 SECRET_KEY
        app.config.from_pyfile("config.py", silent=False)
        app.logger.warning(app.config["SECRET_KEY"])
        app.logger.warning("debug: {0}".format(app.config["DEBUG"]))
    else:
        # load the test config if passed in
        app.config.update(test_config)
    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        app.logger.warning("instance_path: {0}".format(app.instance_path))
        pass
        # a simple page that says hello

    # @app.route("/")
    # @app.route("/hello")
    # def hello():
    #     return "Hello, World!"

    from flaskr import db

    db.init_app(app)
    # 使用 app.register_blueprint() 导入并注册 蓝图。新的代码放在工厂函数的尾部返回应用之前。
    from flaskr import auth

    app.register_blueprint(auth.bp)

    from flaskr import blog

    app.register_blueprint(blog.bp)

    app.add_url_rule("/", endpoint="index")

    return app


# with open(r"gdk.txt", mode="wt") as f:
#     f.write(__name__)
#     f.write(os.getcwd())
if __name__ == "__main__":
    app = create_app()
    app.run(DEBUG=True)
