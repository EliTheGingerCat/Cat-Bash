from flask import Flask, render_template
from werkzeug.exceptions import HTTPException

def initialise_application(application: Flask):
    @application.errorhandler(HTTPException)
    def handle_exception(e):
        return render_template("error.html", e=e), e.code