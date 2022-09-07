from flask import render_template
from flask import Flask, request, redirect, flash, url_for
import pathlib
from werkzeug.utils import secure_filename
import os


print(__name__)
app = Flask(__name__)

BASE_DIR = pathlib.Path(__file__).parent
UPLOAD_FOLDER = BASE_DIR / "uploads/"

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.secret_key = "djskla"

ALLOWED_EXTENSIONS = set(["txt", "pdf", "png", "jpg", "jpeg", "gif"])


@app.route("/hello/<name>")
def hello(name=None):
    return render_template("hello.html", name=name)


@app.route("/")
@app.route("/to_upload")
def to_upload():
    return render_template("upload.html")


@app.route("/upload", methods=["GET", "POST"])
def upload_file():
    if request.method == "POST":
        # check if the post request has the file part
        if "file" not in request.files:
            flash("No file part")
            return redirect(request.url)
        file = request.files["file"]
        # if user does not select file, browser also
        # submit a empty part without filename
        if file.filename == "":
            flash("No selected file")
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config["UPLOAD_FOLDER"], filename))
            return redirect(url_for("to_upload", filename=filename))
        else:
            flash("file type not allowed")
    return redirect(url_for("to_upload"))


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


# app.run(debug=True)
