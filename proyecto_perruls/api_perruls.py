from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from psycopg import connect
from psycopg.rows import dict_row
import os

from dotenv import load_dotenv
load_dotenv()

app = FastAPI(
    title="API PERRULS",
    description="API para el sistema de mascotas comunitarias PERRULS",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
def get_conn():
    return connect(
        host=os.getenv("DB_HOST", "10.7.50.11"),
        dbname=os.getenv("DB_NAME", "perruls"),
        user=os.getenv("DB_USER", "perruls"),
        password=os.getenv("DB_PASS", "ikl5t8G"),
        port=int(os.getenv("DB_PORT", "5432")),
        row_factory=dict_row
    )

@app.get("/mascotas")
def listar_mascotas():
    """
    Lista todas las mascotas.
    """
    sql = """
    SELECT 
        m.chip_id,
        m.nombre_mascota,
        m.raza,
        m.peso AS peso_kg,
        m.edad_estimada,
        m.estado_adop,
        m.nombre_campus
    FROM mascota m
    ORDER BY m.nombre_mascota;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/mascotas/{chip_id}")
def obtener_mascota(chip_id: str):
    """
    Devuelve el detalle de una mascota por chip_id.
    """
    sql = """
    SELECT 
        m.chip_id,
        m.nombre_mascota,
        m.raza,
        m.peso AS peso_kg,
        m.edad_estimada,
        m.estado_adop,
        m.nombre_campus
    FROM mascota m
    WHERE m.chip_id = %s;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (chip_id,))
                row = cur.fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")
        return row
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/sucursales")
def listar_sucursales():
    """
    Devuelve la lista de sucursales/campus registradas.
    """
    sql = """
    SELECT 
        nombre_campus,
        direccion
    FROM sucursal
    ORDER BY nombre_campus;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()

        sucursales = [
            {"nombre_campus": r[0], "direccion": r[1]} for r in rows
        ]

        return {"data": sucursales}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/reportes/mascotas-por-campus")
def mascotas_por_campus():
    """
    Número de mascotas por campus.
    """
    sql = """
    SELECT 
        s.nombre_campus,
        COUNT(m.chip_id) AS total_mascotas
    FROM sucursal s
    LEFT JOIN mascota m 
        ON m.nombre_campus = s.nombre_campus
    GROUP BY s.nombre_campus
    ORDER BY total_mascotas DESC;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/mascotas/{chip_id}/vacunas")
def vacunas_de_mascota(chip_id: str):
    """
    Historial de vacunas de una mascota.
    """
    sql = """
    SELECT 
        v.id_vacuna,
        v.nombre_vacuna,
        v.fecha_aplicacion
    FROM vacuna v
    WHERE v.chip_id = %s
    ORDER BY v.fecha_aplicacion DESC;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (chip_id,))
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/tratamientos")
def tratamientos_hechos():
    """
    Historial de tratamientos realizados.
    """
    sql = """
    SELECT 
        t.id_tratamiento,
        t.chip_id,
        m.nombre_mascota,
        t.descripcion,
        t.fecha_tratamiento_inic,
        t.fecha_tratamiento_fin
    FROM tratamiento t
    JOIN mascota m ON m.chip_id = t.chip_id
    WHERE t.fecha_tratamiento_fin IS NULL OR t.fecha_tratamiento_fin < CURRENT_DATE
    ORDER BY t.fecha_tratamiento_inic;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/mascotas/{chip_id}/tratamientos")
def tratamientos_de_mascota(chip_id: str):
    """
    Lista de tratamientos de una mascota (historial).
    """
    sql = """
    SELECT 
        t.id_tratamiento,
        t.descripcion,
        t.fecha_inicio,
        t.fecha_fin
    FROM tratamiento t
    WHERE t.chip_id = %s
    ORDER BY t.fecha_inicio DESC;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (chip_id,))
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/inventario/comida")
def inventario_comida(critico: bool = False):
    """
    Lista alimentos por campus.
    Si critico = true, solo muestra stock bajo (< 10).
    """
    base_sql = """
    SELECT 
        i.nombre AS nombre_item,
        i.unidad_de_medida,
        i.cantidad,
        i.nombre_campus,
        i.fecha_venc
    FROM inventario i
    WHERE i.tipo = 'Comida'
    """
    if critico:
        base_sql += " AND i.cantidad < 10 "
    base_sql += " ORDER BY i.nombre_campus, i.nombre;"

    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(base_sql)
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/inventario/medicamentos")
def inventario_medicamentos():
    """
    Lista medicamentos por campus, incluyendo gramaje.
    """
    sql = """
    SELECT 
        s.nombre_campus,
        i.nombre AS medicamento,
        i.cantidad,
        med.gramaje
    FROM inventario i
    JOIN sucursal s
        ON i.nombre_campus = s.nombre_campus
    JOIN medicamento med
        ON med.id_item = i.id_item
    WHERE i.tipo = 'Medicamento'
    ORDER BY s.nombre_campus, i.nombre;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/mascotas/{chip_id}/derivaciones")
def derivaciones_de_mascota(chip_id: str):
    """
    Historial de derivaciones de una mascota a veterinarias.
    """
    sql = """
    SELECT 
        d.id_derivacion,
        d.veterinaria,
        d.motivo,
        d.fecha_derivacion
    FROM derivacion d
    WHERE d.chip_id = %s
    ORDER BY d.fecha_derivacion DESC;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (chip_id,))
                rows = cur.fetchall()
        return {"data": rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))