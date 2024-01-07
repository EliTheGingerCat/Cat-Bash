from flask import Blueprint, redirect, render_template

blueprint = Blueprint("site", __name__, url_prefix="/site")


@blueprint.route("/")
def index():
    return render_template("site/index.html")


@blueprint.route("/code")
def code():
    return redirect("https://github.com/EliTheGingerCat/Cat-Bash")


@blueprint.route("/never-asked-questions")
def never_asked_questions():
    return render_template("site/never-asked-questions.html")