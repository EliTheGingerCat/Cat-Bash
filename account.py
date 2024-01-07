import functools
from flask import abort, Blueprint, flash, g, redirect, render_template, request, session, url_for
from typing import Optional
from werkzeug.security import check_password_hash, generate_password_hash
from .database import get_database

blueprint = Blueprint("account", __name__, url_prefix="/account")


def get_user(id: int):
    user = get_database().execute(
        "SELECT * FROM user WHERE id = ?",
        (id,)
    ).fetchone()

    if user:
        return user
    else:
        abort(404, f"No user found with id {id}.")


def signin_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if g.user is None:
            return redirect(url_for("account.signin"))
        
        return view(**kwargs)
    
    return wrapped_view


@blueprint.before_app_request
def load_logged_in_user():
    user_id = session.get("user_id")

    if user_id is None:
        g.user = None
    else:
        g.user = get_user(user_id)


@blueprint.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        username = request.form["username"]
        userpass = request.form["userpass"]
        database = get_database()
        error = None

        if not username or not userpass:
            error = "Username and userpass required."
        
        if error is None:
            try:
                database.execute(
                    "INSERT INTO user (name, pass) VALUES (?, ?)",
                    (username, generate_password_hash(userpass))
                )
                database.commit()
            except database.IntegrityError:
                error = f"User {username} is taken."
            else:
                id = database.execute(
                    "SELECT id FROM user WHERE name = ?",
                    (username,)
                ).fetchone()[0]
                if id == 1:
                    database.execute(
                        "UPDATE user SET roles = 'owner' WHERE id = ?",
                        (id,)
                    )
                    database.commit()
                
                response = redirect(url_for("account.signin"), code=307)
                response.headers["username"] = username
                response.headers["userpass"] = userpass
                session["signup"] = True
                return response
        
        flash(error, "error")
    
    return render_template("account/signup.html")


@blueprint.route("/signdown", methods=["POST"])
@signin_required
def signdown():
    database = get_database()
    database.execute(
        "DELETE FROM user WHERE id = ?",
        (g.user["id"],)
    )
    database.execute(
        "DELETE FROM post WHERE author_id = ?",
        (g.user["id"],)
    )
    database.commit()

    session.clear()
    flash(f"Successfully deleted account {g.user['name']} and all its posts.", "success")
    return redirect(url_for("posts.index"))


@blueprint.route("/signin", methods=["GET", "POST"])
def signin():
    if request.method == "POST":
        username = request.form["username"]
        userpass = request.form["userpass"]
        database = get_database()
        error = None
        user = database.execute(
            "SELECT * FROM user WHERE name = ?",
            (username,)
        ).fetchone()

        if user is None or not check_password_hash(user["pass"], userpass):
            error = "No account found with those credentials."
        
        if error is None:
            signup = session.get("signup")

            session.clear()
            session["user_id"] = user["id"]

            if signup:
                flash(f"Successfully signed up as {username}.", "success")
            else:
                flash(f"Successfully logged in as {username}.", "success")
            
            return redirect(url_for("posts.index"))
        
        flash(error, "error")
    
    return render_template("account/signin.html")


@blueprint.route("/signout")
def signout():
    session.clear()
    flash(f"Successfully logged out of {g.user['name']}.", "success")
    return redirect(url_for("posts.index"))


@blueprint.route("/profile")
@signin_required
def profile():
    return render_template("account/profile.html", user=g.user)


@blueprint.route("/profile/<int:id>")
def profile_id(id: int):
    return render_template("account/profile.html", user=get_user(id))