import functools

from flask import (
    Blueprint,
    flash,
    g,
    redirect,
    render_template,
    request,
    session,
    url_for,
    current_app,
)
from werkzeug.security import check_password_hash, generate_password_hash

from flaskr.db import get_db

"""
Blueprint 是一种组织一组相关视图及其他代码的方式。与把视图
及其他 代码直接注册到应用的方式不同，蓝图方式是把它们注册到
蓝图，然后在工厂函数中 把蓝图注册到应用
"""


# 这里创建了一个名称为 'auth' 的 Blueprint 。和应用对象一样，
# 蓝图需要知道是在哪里定义的，因此把 __name__ 作为函数的第二个参数。 url_prefix 会添加到所有与该蓝图关联的 URL 前面。
bp = Blueprint("auth", __name__, url_prefix="/auth")

"""
@bp.route 关联了 URL /register 和 register 视图函数。当 Flask 
收到一个指向 /auth/register 的请求时就会调用 register 视图并把
其返回值作为响应
"""


@bp.route("/register", methods=["POST", "GET"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        error = None

        if not username:
            error = "Username is required"
        if not password:
            error = "Password is required"

        if error is None:
            try:
                db, db_cur = get_db()

                db_cur.execute(
                    'insert into "user"(username,password) values (%s,%s)',
                    (username, generate_password_hash(password)),
                )
                db.commit()
            except db.IntegrityError:
                error = f"User {username} is already registered."
            else:
                return redirect(url_for("auth.login"))
        flash(error)
    return render_template("auth/register.html")


@bp.route("/login", methods=["POST", "GET"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        error = None

        db_cur = get_db()[1]
        db_cur.execute('select * from "user" where username = %s', (username,))
        user = db_cur.fetchone()
        if user is None:
            error = "Incorrect username."
        elif not check_password_hash(user["password"], password):
            error = "Incorrect password."

        if error is None:
            session.clear()
            session["user_id"] = user["id"]
            return redirect(url_for("blog.index"))

        flash(error)
    return render_template("auth/login.html")


"""
bp.before_app_request() 注册一个 在视图函数之前运行的函数，不论其 URL 
是什么。 load_logged_in_user 检查用户 id 是否已经储存在 session 中，
并从数据库中获取用户数据，然后储存在 g.user 中。 g.user 的持续时间比请
求要长。 如果没有用户 id ，或者 id 不存在，那么 g.user 将会是 None 
"""


@bp.before_app_request
def load_logged_in_user():
    user_id = session.get("user_id")

    if user_id is None:
        g.user = None
        current_app.logger.warning("this is load_logged_in_user1")
    else:
        get_db()[1].execute('SELECT * FROM "user" WHERE id = %s', (user_id,))
        g.user = get_db()[1].fetchone()
        current_app.logger.warning("this is load_logged_in_user2")


"""
注销的时候需要把用户 id 从 session 中移除。 然后 load_logged_in_user 
就不会在后继请求中载入用户了。
"""


@bp.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


"""
用户登录以后才能创建、编辑和删除博客帖子。在每个视图中可以使用 装饰器 来
完成这个工作。
"""


def login_required(view):
    @functools.wraps(view)
    def wrapped_view(*args, **kwargs):
        if g.user is None:
            return redirect(url_for("auth.login"))
        return view(*args, **kwargs)

    return wrapped_view
