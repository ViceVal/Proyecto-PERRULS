import csv
import threading
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import psycopg
from psycopg.rows import tuple_row

class PGClient:
    def __init__(self):
        self.conn: psycopg.Connection | None = None

    def connect(self, host: str, dbname: str, user: str, password: str, port: int = 5432):
        if self.conn and not self.conn.closed:
            self.conn.close()
        self.conn = psycopg.connect(host=host, dbname=dbname, user=user, password=password, port=port, row_factory=tuple_row)

    def is_connected(self) -> bool:
        return self.conn is not None and not self.conn.closed

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()

    def run_query(self, sql: str, params: tuple | None = None):
        if not self.is_connected():
            raise RuntimeError("No hay conexión activa.")
        with self.conn.cursor() as cur:
            cur.execute(sql, params or ())
            columns = []
            try:
                if cur.description:
                    columns = [d.name for d in cur.description]
            except Exception:
                columns = []
            rows = []
            try:
                rows = cur.fetchall() if cur.description else []
            except psycopg.ProgrammingError:
                rows = []
            return columns, rows

    def table_schema(self, table_name: str):
        sql = (
            "SELECT column_name, data_type, is_nullable, column_default "
            "FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position"
        )
        return self.run_query(sql, (table_name,))

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("PostgreSQL GUI – Consultas rápidas (v2)")
        self.geometry("1200x720")
        self.minsize(1024, 640)

        self.client = PGClient()

        self.current_columns: list[str] = []
        self.current_rows: list[tuple] = []
        self.page_size_var = tk.IntVar(value=100)
        self.page_var = tk.IntVar(value=1)

        self.style = ttk.Style()
        self.style.configure("TButton", padding=6)
        self.style.configure("TLabel", padding=2)
        self.style.configure("TEntry", padding=2)
        self.style.configure("Treeview.Heading", font=("Segoe UI", 10, "bold"))

        self._build_layout()
        self._toggle_controls(False)

        self.host_var.set("10.7.50.11")
        self.db_var.set("perruls")
        self.user_var.set("perruls")
        self.port_var.set("5432")

    def _build_layout(self):
        top = ttk.Frame(self, padding=(10, 8))
        top.pack(fill=tk.X)

        self.host_var = tk.StringVar()
        self.port_var = tk.StringVar(value="5432")
        self.db_var = tk.StringVar()
        self.user_var = tk.StringVar()
        self.pw_var = tk.StringVar()

        def add_labeled_entry(parent, text, var, width=18, show=None):
            f = ttk.Frame(parent)
            ttk.Label(f, text=text).pack(side=tk.LEFT)
            e = ttk.Entry(f, textvariable=var, width=width, show=show)
            e.pack(side=tk.LEFT, padx=(6, 0))
            return f

        row1 = ttk.Frame(top)
        row1.pack(fill=tk.X)
        add_labeled_entry(row1, "Host:", self.host_var, 18).pack(side=tk.LEFT, padx=(0, 10))
        add_labeled_entry(row1, "Puerto:", self.port_var, 8).pack(side=tk.LEFT, padx=(0, 10))
        add_labeled_entry(row1, "Base:", self.db_var, 16).pack(side=tk.LEFT, padx=(0, 10))
        add_labeled_entry(row1, "Usuario:", self.user_var, 14).pack(side=tk.LEFT, padx=(0, 10))
        add_labeled_entry(row1, "Clave:", self.pw_var, 14, show="*").pack(side=tk.LEFT, padx=(0, 10))

        self.btn_connect = ttk.Button(row1, text="Conectar", command=self.on_connect)
        self.btn_connect.pack(side=tk.LEFT)
        self.btn_disconnect = ttk.Button(row1, text="Desconectar", command=self.on_disconnect)
        self.btn_disconnect.pack(side=tk.LEFT, padx=(6, 0))

        main = ttk.Frame(self, padding=8)
        main.pack(fill=tk.BOTH, expand=True)

        left = ttk.Frame(main)
        left.pack(side=tk.LEFT, fill=tk.Y)

        right = ttk.Frame(main)
        right.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        actions = ttk.LabelFrame(left, text="Acciones rápidas", padding=8)
        actions.pack(fill=tk.X, pady=(0, 10))

        self.btn_list_tables = ttk.Button(actions, text="Listar tablas (public)", command=self.on_list_tables)
        self.btn_list_tables.pack(fill=tk.X, pady=3)

        # NUEVAS ACCIONES RÁPIDAS
        self.btn_q_mascotas_vacunadas = ttk.Button(actions, text="Mascotas vacunadas en Isabel Bongard", 
                                                 command=lambda: self.run_sql_async("""
SELECT mascota.chip_id, mascota.nombre_mascota, mascota.raza, sucursal.nombre_campus, vacuna.nombre_vacuna, vacuna.fecha_aplicacion
FROM sucursal
JOIN mascota ON sucursal.nombre_campus = mascota.nombre_campus 
JOIN vacuna ON mascota.chip_id = vacuna.chip_id 
WHERE sucursal.nombre_campus = 'Isabel Bongard'
ORDER BY vacuna.fecha_aplicacion DESC;
"""))
        self.btn_q_mascotas_vacunadas.pack(fill=tk.X, pady=3)

        self.btn_q_medicamentos_campus = ttk.Button(actions, text="Medicamentos por campus", 
                                                  command=lambda: self.run_sql_async("""
SELECT sucursal.nombre_campus, inventario.nombre AS medicamento, inventario.cantidad, medicamento.gramaje
FROM inventario
JOIN sucursal ON inventario.nombre_campus = sucursal.nombre_campus
JOIN medicamento ON inventario.id_item = medicamento.id_item
ORDER BY sucursal.nombre_campus, inventario.nombre;
"""))
        self.btn_q_medicamentos_campus.pack(fill=tk.X, pady=3)

        self.btn_q_comida_mascotas = ttk.Button(actions, text="Comida y mascotas por campus", 
                                              command=lambda: self.run_sql_async("""
SELECT 
    sucursal.nombre_campus,
    COUNT(mascota.chip_id) AS total_mascotas,
    COALESCE((
        SELECT SUM(cantidad) 
        FROM inventario 
        WHERE inventario.nombre_campus = sucursal.nombre_campus 
        AND inventario.tipo = 'Comida'
    ), 0) AS stock_total_alimento
FROM sucursal
LEFT JOIN mascota ON mascota.nombre_campus = sucursal.nombre_campus
GROUP BY sucursal.nombre_campus
ORDER BY stock_total_alimento DESC;
"""))
        self.btn_q_comida_mascotas.pack(fill=tk.X, pady=3)

        self.btn_q_stock_critico = ttk.Button(actions, text="Alimentos con stock crítico relativo", 
                                            command=lambda: self.run_sql_async("""
SELECT sucursal.nombre_campus, inventario.nombre AS Comida, inventario.cantidad,
 COUNT(mascota.chip_id) AS cantidad_mascotas,  inventario.cantidad / COUNT(mascota.chip_id) AS kg_por_mascota
FROM inventario
JOIN sucursal ON inventario.nombre_campus = sucursal.nombre_campus
LEFT JOIN mascota ON mascota.nombre_campus = sucursal.nombre_campus
WHERE inventario.tipo = 'Comida'
GROUP BY sucursal.nombre_campus, inventario.nombre, inventario.cantidad
HAVING (inventario.cantidad / COUNT(mascota.chip_id)) < 10
ORDER BY kg_por_mascota ASC;
"""))
        self.btn_q_stock_critico.pack(fill=tk.X, pady=3)

        self.btn_q_mascotas_derivadas = ttk.Button(actions, text="Mascotas derivadas", 
                                                 command=lambda: self.run_sql_async("""
SELECT derivacion.id_derivacion, derivacion.fecha, derivacion.motivo, derivacion.ubicacion_vet, mascota.chip_id, mascota.nombre_mascota, sucursal.nombre_campus
FROM derivacion
JOIN mascota ON derivacion.chip_id = mascota.chip_id
JOIN sucursal ON mascota.nombre_campus = sucursal.nombre_campus
ORDER BY derivacion.fecha DESC;
"""))
        self.btn_q_mascotas_derivadas.pack(fill=tk.X, pady=3)

        pick = ttk.LabelFrame(left, text="Ver datos de una tabla", padding=8)
        pick.pack(fill=tk.X)

        self.tables_var = tk.StringVar()
        self.cmb_tables = ttk.Combobox(pick, textvariable=self.tables_var, state="readonly")
        self.cmb_tables.pack(fill=tk.X, pady=(0, 6))

        btns_tbl = ttk.Frame(pick)
        btns_tbl.pack(fill=tk.X)
        ttk.Button(btns_tbl, text="Cargar tabla", command=self.on_load_selected_table).pack(side=tk.LEFT, expand=True, fill=tk.X)
        ttk.Button(btns_tbl, text="Ver esquema", command=self.on_view_schema).pack(side=tk.LEFT, expand=True, fill=tk.X, padx=(6,0))

        sql_box = ttk.LabelFrame(right, text="SQL", padding=8)
        sql_box.pack(fill=tk.X)

        self.txt_sql = tk.Text(sql_box, height=4, wrap=tk.NONE)
        self.txt_sql.pack(fill=tk.X)
        self.txt_sql.insert("1.0", "SELECT * FROM sucursal;")

        btns = ttk.Frame(sql_box)
        btns.pack(fill=tk.X, pady=(6, 0))
        self.btn_exec = ttk.Button(btns, text="Ejecutar SQL", command=self.on_execute_sql)
        self.btn_exec.pack(side=tk.LEFT)
        self.btn_clear = ttk.Button(btns, text="Limpiar", command=lambda: self.txt_sql.delete("1.0", tk.END))
        self.btn_clear.pack(side=tk.LEFT, padx=(6, 0))

        table_box = ttk.LabelFrame(right, text="Resultados", padding=8)
        table_box.pack(fill=tk.BOTH, expand=True, pady=(8, 0))

        self.tree = ttk.Treeview(table_box, columns=(), show="headings")
        vsb = ttk.Scrollbar(table_box, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(table_box, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscroll=vsb.set, xscroll=hsb.set)
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        vsb.pack(side=tk.LEFT, fill=tk.Y)
        hsb.pack(side=tk.BOTTOM, fill=tk.X)

        pager = ttk.Frame(right)
        pager.pack(fill=tk.X, pady=(6,0))
        ttk.Label(pager, text="Tamaño página:").pack(side=tk.LEFT)
        self.ent_page_size = ttk.Entry(pager, textvariable=self.page_size_var, width=6)
        self.ent_page_size.pack(side=tk.LEFT, padx=(4,10))
        self.btn_first = ttk.Button(pager, text="⏮ Primero", command=self.on_first_page)
        self.btn_prev = ttk.Button(pager, text="◀ Anterior", command=self.on_prev_page)
        self.btn_next = ttk.Button(pager, text="Siguiente ▶", command=self.on_next_page)
        self.btn_last = ttk.Button(pager, text="Último ⏭", command=self.on_last_page)
        self.btn_first.pack(side=tk.LEFT, padx=2)
        self.btn_prev.pack(side=tk.LEFT, padx=2)
        self.btn_next.pack(side=tk.LEFT, padx=2)
        self.btn_last.pack(side=tk.LEFT, padx=2)

        self.lbl_page_info = ttk.Label(pager, text="Página 0 de 0", anchor="e")
        self.lbl_page_info.pack(side=tk.RIGHT)

        export = ttk.Frame(right)
        export.pack(fill=tk.X, pady=(4,0))
        self.btn_export_page = ttk.Button(export, text="Exportar CSV (página)", command=lambda: self.export_csv(current_only=True))
        self.btn_export_all = ttk.Button(export, text="Exportar CSV (todo)", command=lambda: self.export_csv(current_only=False))
        self.btn_export_page.pack(side=tk.LEFT)
        self.btn_export_all.pack(side=tk.LEFT, padx=(6,0))

        self.status = ttk.Label(self, text="Desconectado", anchor="w", relief=tk.SUNKEN)
        self.status.pack(fill=tk.X, side=tk.BOTTOM)

    def _toggle_controls(self, connected: bool):
        self.btn_connect.configure(state=("disabled" if connected else "normal"))
        self.btn_disconnect.configure(state=("normal" if connected else "disabled"))
        widgets = [self.btn_list_tables, self.btn_q_mascotas_vacunadas, self.btn_q_medicamentos_campus, 
                   self.btn_q_comida_mascotas, self.btn_q_stock_critico, self.btn_q_mascotas_derivadas, 
                   self.btn_exec, self.btn_clear, self.cmb_tables, self.btn_first, self.btn_prev, 
                   self.btn_next, self.btn_last, self.ent_page_size, self.btn_export_page, self.btn_export_all]
        for w in widgets:
            w.configure(state=("normal" if connected else "disabled"))

    def on_connect(self):
        host = self.host_var.get().strip()
        db = self.db_var.get().strip()
        user = self.user_var.get().strip()
        pw = self.pw_var.get()
        try:
            port = int(self.port_var.get().strip() or "5432")
        except ValueError:
            messagebox.showerror("Error", "El puerto debe ser numérico.")
            return
        try:
            self.client.connect(host, db, user, pw, port)
            self.status.configure(text=f"Conectado a {db}@{host}:{port} como {user}")
            self._toggle_controls(True)
            self.on_list_tables()
        except Exception as e:
            messagebox.showerror("Conexión fallida", str(e))
            self.status.configure(text="Desconectado")

    def on_disconnect(self):
        try:
            self.client.close()
        finally:
            self._toggle_controls(False)
            self.status.configure(text="Desconectado")
            self._clear_tree()
            self._reset_pager()

    def on_list_tables(self):
        sql = """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name
        """
        self.run_sql_async(sql, post=lambda cols, rows: self._fill_tables_combo([r[0] for r in rows]))

    def _fill_tables_combo(self, names: list[str]):
        self.cmb_tables["values"] = names
        if names:
            self.cmb_tables.current(0)

    def on_load_selected_table(self):
        name = self.tables_var.get().strip()
        if not name:
            messagebox.showinfo("Tabla", "Selecciona una tabla primero.")
            return
        self.run_sql_async(f"SELECT * FROM {psql_ident(name)} ORDER BY 1")

    def on_view_schema(self):
        name = self.tables_var.get().strip()
        if not name:
            messagebox.showinfo("Esquema", "Selecciona una tabla primero.")
            return
        def after(cols, rows):
            self._set_current(cols, rows)
            self._render_page()
        self.status.configure(text="Obteniendo esquema…")
        threading.Thread(target=self._schema_worker, args=(name, after), daemon=True).start()

    def _schema_worker(self, table_name, post):
        try:
            cols, rows = self.client.table_schema(table_name)
            self.after(0, lambda: self._display_result(cols, rows, f"Esquema de {table_name}", post))
        except Exception as e:
            self.after(0, lambda: self._on_query_error(e))

    def on_execute_sql(self):
        sql = self.txt_sql.get("1.0", tk.END).strip()
        if not sql:
            messagebox.showinfo("SQL", "Ingresa una sentencia SQL.")
            return
        self.run_sql_async(sql)

    def run_sql_async(self, sql: str, post=None):
        self.status.configure(text="Ejecutando…")
        self.btn_exec.configure(state="disabled")

        def worker():
            try:
                cols, rows = self.client.run_query(sql)
                self.after(0, lambda: self._display_result(cols, rows, sql, post))
            except Exception as e:
                self.after(0, lambda: self._on_query_error(e))
        threading.Thread(target=worker, daemon=True).start()

    def _display_result(self, columns, rows, sql, post):
        self._set_current(columns, rows)
        self._render_page()
        self.status.configure(text=f"{len(rows)} filas · OK")
        self.btn_exec.configure(state="normal")
        if post:
            try:
                post(columns, rows)
            except Exception:
                pass

    def _on_query_error(self, e: Exception):
        self.btn_exec.configure(state="normal")
        messagebox.showerror("Error de consulta", str(e))
        self.status.configure(text="Error")

    def _set_current(self, columns, rows):
        self.current_columns = list(columns or [])
        self.current_rows = list(rows or [])
        self.page_var.set(1)

    def _reset_pager(self):
        self.current_columns = []
        self.current_rows = []
        self.page_var.set(1)
        self._update_page_label()

    def _render_page(self):
        self._populate_tree(self.current_columns, self._page_slice())
        self._update_page_label()

    def _page_slice(self):
        if not self.current_rows:
            return []
        try:
            size = max(1, int(self.page_size_var.get()))
        except Exception:
            size = 100
            self.page_size_var.set(size)
        total = len(self.current_rows)
        pages = max(1, (total + size - 1) // size)
        page = min(max(1, int(self.page_var.get())), pages)
        start = (page - 1) * size
        end = min(start + size, total)
        return self.current_rows[start:end]

    def _update_page_label(self):
        total = len(self.current_rows)
        try:
            size = max(1, int(self.page_size_var.get()))
        except Exception:
            size = 100
        pages = max(1, (total + size - 1) // size)
        page = min(max(1, int(self.page_var.get())), pages)
        self.lbl_page_info.configure(text=f"Página {page} de {pages} · {total} filas")

    def on_first_page(self):
        if self.current_rows:
            self.page_var.set(1)
            self._render_page()

    def on_prev_page(self):
        if self.current_rows and self.page_var.get() > 1:
            self.page_var.set(self.page_var.get() - 1)
            self._render_page()

    def on_next_page(self):
        if not self.current_rows:
            return
        total = len(self.current_rows)
        size = max(1, int(self.page_size_var.get()))
        pages = max(1, (total + size - 1) // size)
        if self.page_var.get() < pages:
            self.page_var.set(self.page_var.get() + 1)
            self._render_page()

    def on_last_page(self):
        if not self.current_rows:
            return
        total = len(self.current_rows)
        size = max(1, int(self.page_size_var.get()))
        pages = max(1, (total + size - 1) // size)
        self.page_var.set(pages)
        self._render_page()

    def export_csv(self, current_only: bool):
        if not self.current_columns:
            messagebox.showinfo("Exportar", "No hay datos para exportar.")
            return
        rows = self._page_slice() if current_only else self.current_rows
        if not rows:
            messagebox.showinfo("Exportar", "No hay filas en esta selección.")
            return
        path = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV", "*.csv")],
            title="Guardar como CSV"
        )
        if not path:
            return
        try:
            with open(path, "w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow(self.current_columns)
                for r in rows:
                    writer.writerow(list(r))
            messagebox.showinfo("Exportar", f"Exportado correctamente://{path}")
        except Exception as e:
            messagebox.showerror("Exportar", str(e))

    def _clear_tree(self):
        for c in self.tree["columns"]:
            self.tree.heading(c, text="")
            self.tree.column(c, width=0)
        self.tree.delete(*self.tree.get_children())
        self.tree["columns"] = ()

    def _populate_tree(self, columns, rows):
        self._clear_tree()
        if not columns:
            return
        self.tree["columns"] = columns
        for c in columns:
            self.tree.heading(c, text=c)
            self.tree.column(c, width=max(80, len(c) * 10))
        for r in rows:
            self.tree.insert("", tk.END, values=list(r))

def psql_ident(name: str) -> str:
    """Devuelve un identificador SQL escapado con comillas dobles si es necesario.
    Evita inyección en nombres de tabla/columna (no para valores).
    """
    if not name:
        raise ValueError("Identificador vacío")
    if any(ch in name for ch in "\"';` "):
        raise ValueError("Nombre de tabla/columna inválido")
    return f'"{name}"' if not name.islower() or not name.isidentifier() else name

if __name__ == "__main__":
    app = App()
    app.mainloop()