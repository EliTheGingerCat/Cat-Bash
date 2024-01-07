import os
from flask import Flask


def create_app(test_configuration=None):
    application = Flask(__name__, instance_relative_config=True)
    application.config.from_mapping(
        SECRET_KEY="dev",
        DATABASE=os.path.join(application.instance_path, "app.sqlite")
    )

    if test_configuration is None:
        application.config.from_pyfile("config.py", silent=True)
    else:
        application.config.from_mapping(test_configuration)
    
    try:
        os.makedirs(application.instance_path)
    except OSError:
        pass

    from . import database
    database.initialise_application(application)

    from . import account
    application.register_blueprint(account.blueprint)

    from . import posts
    application.register_blueprint(posts.blueprint)

    from . import site
    application.register_blueprint(site.blueprint)

    from . import errors
    errors.initialise_application(application)

    return application