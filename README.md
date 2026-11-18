# Backstage — SO II / TP N.º 4 2026 — paquete dual Docker / LXC

Aplicación Flask de **solo lectura** para PostgreSQL. **El mismo código fuente se ejecuta en Docker o LXC**. Seleccionar **un solo modo** por aplicación.

- Base de datos: `musicos_bandas`. Rol: `app_musicos`.
- Acceso a PostgreSQL exclusivamente por funciones almacenadas (no por tablas).
- Bootstrap 5.3.6 se distribuye como archivo CSS local (licencia MIT); no requiere CDN ni Google Fonts en el navegador.
- El puerto interno HTTP de la app es `8000`; no debe publicarse en Internet.

## A. Docker: dentro de la VM Debian 13 con PostgreSQL y Apache

```bash
cp .env.example .env
# Editar DB_HOST en .env: debe ser la IP de la VM Debian (NO 127.0.0.1).
docker compose up --build -d
docker compose ps
curl -f http://127.0.0.1:5000/health
```

Por seguridad, el contenedor usa red Docker **bridge** y publica el puerto del host solo en `127.0.0.1:5000` para Apache. Desde Docker, `DB_HOST` apunta a la IP LAN de la VM Debian con PostgreSQL. El servidor PostgreSQL debe aceptar el origen de red Docker autorizado.

Identificar la subred real que Docker asignó a esta aplicación:

```bash
docker network inspect so2_tpn4_musicos_net --format '{{(index .IPAM.Config 0).Subnet}}'
```

Si hay un proxy institucional para descargar imágenes, configurar el proxy del daemon Docker en Debian. Para el **paso pip install del build** se pueden definir `HTTP_PROXY` y `HTTPS_PROXY` en `.env` sin fijarlos en la imagen. Las consultas locales a la BD **no pasan por el proxy de Internet**.

## B. LXC: dentro de un CT Debian creado en Proxmox

Copiar todos los archivos de esta carpeta **al contenedor LXC**. Ejecutar allí como root:

```bash
cp .env.example .env
# Editar DB_HOST en .env: IP LAN de la VM Debian que aloja PostgreSQL.
./install-lxc.sh
systemctl status so2-musicos --no-pager
curl -f http://127.0.0.1:8000/health
```

El instalador crea `/opt/so2/musicos`, un entorno virtual Python con Flask, Psycopg y Gunicorn, y el servicio `so2-musicos.service`. **No se instala Docker dentro de LXC**. Abrirá TCP/8000 sobre la red propia del CT para que Apache, en la VM, pueda alcanzarlo. Restringir acceso directo al puerto 8000 a la VM si el firewall de la LAN lo permite.

Para actualizar los archivos de la app: volver a copiar la carpeta y ejecutar `./install-lxc.sh`.

## C. Apache y URLs estables

Se prepara en la carpeta `../infraestructura/` una herramienta para elegir qué aplicación va en Docker y cuál en LXC; Apache publica:

- `http://IP_VM/musicos/`
- `http://IP_VM/discos/`

Los recursos estáticos y las peticiones a la API respetan el prefijo de la URL. Acceso directo a `/` también funciona.

## Precauciones

- `.env` contiene una contraseña educativa conocida: **solo para el laboratorio**. No incluirlo en imágenes Docker ni repositorios públicos.
- PostgreSQL en la VM: adaptar `listen_addresses` y `pg_hba.conf` a la IP LAN de la VM y a los **orígenes reales** Docker/LXC. No habilitar accesos universales.
- La instalación de Python y pip desde Internet puede exigir proxy en el CT; no es necesario durante el funcionamiento normal de la app.
- Prueba funcional completa de Docker/LXC y PostgreSQL real: pendiente de ejecutar en el laboratorio.

## Estructura

`app.py`, `requirements.txt`, `templates/`, `static/`, `Dockerfile`, `compose.yaml`, `.env.example`, `install-lxc.sh`.
