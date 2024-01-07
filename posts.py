from flask import Blueprint, flash, g, redirect, render_template, request, url_for
from werkzeug.exceptions import abort
from .account import signin_required
from .database import get_database

blueprint = Blueprint("posts", __name__, url_prefix="/")


def get_post(id, check_author=True):
    post = get_database().execute(
        "SELECT p.id, title, body, p.created, author_id, name FROM post p JOIN user u ON p.author_id = u.id WHERE p.id = ?",
        (id,)
    ).fetchone()

    if post is None:
        abort(404, f"No post found with id {id}.")
    
    if check_author and post["author_id"] != g.user["id"]:
        abort(403, f"No permission to edit post with id {id}.")
    
    return post


@blueprint.route("/", methods=["GET"])
def index():
    database = get_database()
    posts = database.execute(
        "SELECT p.id, title, body, p.created, author_id, name FROM post p JOIN user u ON p.author_id = u.id ORDER BY p.created DESC"
    ).fetchall()
    return render_template("posts/index.html", posts=posts)


@blueprint.route("/create", methods=["GET", "POST"])
@signin_required
def create():
    if request.method == "POST":
        title = request.form["title"]
        body = request.form["body"]
        error = None

        if not title or not body:
            error = "Title and body required."
        
        if error is None:
            database = get_database()
            database.execute(
                "INSERT INTO post (title, body, author_id) VALUES (?, ?, ?)",
                (title, body, g.user["id"])
            )
            database.commit()
            flash("Successfully created post.", "success")
            return redirect(url_for("posts.index"))
        
        flash(error, "error")
    
    return render_template("posts/create.html")


@blueprint.route("/<int:id>")
def view(id: int):
    return render_template("posts/view.html", post=get_post(id, False))


@blueprint.route("/<int:id>/update", methods=["GET", "POST"])
@signin_required
def update(id):
    post = get_post(id)

    if request.method == "POST":
        title = request.form["title"]
        body = request.form["body"]
        error = None

        if not title or not body:
            error = "Title and body required."
        
        if error is None:
            database = get_database()
            database.execute(
                "UPDATE post SET title = ?, body = ? WHERE id = ?",
                (title, body, id)
            )
            database.commit()
            flash("Successfuly updated post.", "success")
            return redirect(url_for("posts.index"))
        
        flash(error, "error")
    
    return render_template("posts/update.html", post=post)


@blueprint.route("/<int:id>/delete", methods=["POST"])
@signin_required
def delete(id):
    get_post(id)
    database = get_database()
    database.execute(
        "DELETE FROM post WHERE id = ?",
        (id,)
    )
    database.commit()
    flash("Successfully deleted post.", "success")
    return redirect(url_for("posts.index"))