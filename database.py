import sqlite3, click
from flask import current_app, Flask, g


def get_database() -> sqlite3.Connection:
    if "database" not in g:
        g.database = sqlite3.connect(
            current_app.config["DATABASE"],
            detect_types=sqlite3.PARSE_DECLTYPES
        )
        g.database.row_factory = sqlite3.Row
    
    return g.database


def close_database(e):
    database = g.pop("database", None)

    if database is not None:
        database.close()


def initialise_database():
    database = get_database()

    with current_app.open_resource("schema.sql") as file:
        database.executescript(file.read().decode("utf8"))


@click.command("init-db")
def command_initialise_database():
    initialise_database()
    click.echo("Initialised the database.")


def initialise_application(application: Flask):
    application.teardown_appcontext(close_database)
    application.cli.add_command(command_initialise_database)