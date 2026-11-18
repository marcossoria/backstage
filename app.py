"""TP N.º 4 - Sistemas Operativos II (2026) | Músicos y bandas."""

import logging
import os

import psycopg
from psycopg.rows import dict_row
from flask import Flask, jsonify, render_template
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
# Apache envía X-Forwarded-Prefix; sin proxy también funciona en /.
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=0, x_proto=0, x_host=0, x_port=0, x_prefix=1)
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))


def conectar_db():
    """Conecta usando las credenciales inyectadas en el contenedor."""
    return psycopg.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "musicos_bandas"),
        user=os.getenv("DB_USER", "app_musicos"),
        password=os.environ["DB_PASSWORD"],
        connect_timeout=4,
        autocommit=True,
        row_factory=dict_row,
    )


@app.get("/")
def inicio():
    musicos = []
    db_disponible = True
    try:
        with conectar_db() as conn:
            with conn.cursor() as cursor:
                # La lógica y los privilegios de lectura están en PostgreSQL.
                cursor.execute("SELECT * FROM public.listar_musicos()")
                musicos = cursor.fetchall()
    except (psycopg.Error, OSError, KeyError, ValueError):
        app.logger.exception("No fue posible obtener el listado de músicos")
        db_disponible = False

    return render_template(
        "index.html", musicos=musicos, db_disponible=db_disponible
    )


@app.get("/api/musicos/<int:musico_id>")
def detalle_musico(musico_id):
    if musico_id <= 0:
        return jsonify(error="Identificador inválido."), 400

    try:
        with conectar_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT * FROM public.obtener_musico(%s::integer)",
                    (musico_id,),
                )
                musico = cursor.fetchone()
    except (psycopg.Error, OSError, KeyError, ValueError):
        app.logger.exception("No fue posible consultar el músico %s", musico_id)
        return jsonify(error="No se pudo consultar PostgreSQL."), 503

    if musico is None:
        return jsonify(error="No se encontró el músico seleccionado."), 404

    return jsonify(instrumento=musico["instrumento"], banda=musico["banda"])


@app.get("/health")
def salud():
    """Comprueba únicamente que la aplicación web está funcionando."""
    return jsonify(servicio="musicos-bandas", estado="ok")


if __name__ == "__main__":
    # Ejecución local manual; en Docker se utiliza gunicorn.
    app.run(host="127.0.0.1", port=8000)
