import json, os
from flask import Flask, request, session, render_template, redirect, url_for

DATA_FOLDER_NAME = "users"

NOTIFICATIONS = {
    None: "Nothing.",
    "signup": "Signed up successfully.",
    "username-taken": "The requested username is already in use."
}

app = Flask(__name__)
app.config.from_pyfile("../config.py") #has secret key


def renderWithData(page: str):
    return render_template(page, info={
        "username": session.get("username", "guest"),
        "notification": NOTIFICATIONS[session.get("notification")]
    })

def getUserFilePath(username: str):
    return os.path.join(app.root_path, DATA_FOLDER_NAME, f"{username}.txt")

def checkUserExists(username: str):
    return os.path.exists(getUserFilePath(username))

def saveUserData(data: dict):
    data = json.dumps(data)
    with open(getUserFilePath(data["username"]), "w") as f:
        f.write(str(data))
    return None

def loadUserData(username: str):
    with open(getUserFilePath(username), "r") as f:
        data = f.read()
    return json.loads(data)

def login(username: str):
    session["username"] = username
    return redirect("/profile")


@app.route("/", methods=["GET", "POST"])
def page_index():
    return renderWithData("index.html")
    

@app.route("/signup", methods=["GET"])
def page_signup():
    if session.get("username"):
        return renderWithData("index.html")

    if request.method == "POST":
        username = request.form["username"]
        userpass = request.form["userpass"]

        if not checkUserExists(username):
            saveUserData({
                username,
                userpass
            })
            session["notification"] = "signup"
            return login(username)
        else:
            session["notification"] = "username-taken"
    
    return renderWithData("signup.html")

@app.route("/login", methods=["GET", "POST"])
def page_login():
    if session.get("username"):
        return renderWithData("index.html")

    if request.method == "POST":
        username = request.form["username"]
        userpass = request.form["userpass"]
        
        if checkUserExists(username):
            data = loadUserData(username)
            if userpass == data["userpass"]:
                return login(username)
        
        session["notification"] = "invalid login"
    
    return renderWithData("login.html")

@app.route("/logout")
def page_logout():
    session.clear()
    session["notification"] = "logout"
    return redirect("/")

@app.route("/profile", methods=["GET"])
def page_profile():
    return renderWithData("profile.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=81)