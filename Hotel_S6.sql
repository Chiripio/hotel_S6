-------------------------------------------------------
-- INGENIERÍA DE SOFTWARE - SEMANA 6
-- Script integrado (basado en tu S5 + mejoras S6)
-- Esquema: HOTEL (Oracle)
-- Contiene: DDL + DML + consultas de evidencia + CRUD demo
-- Ejecutar por bloques
-------------------------------------------------------

-- =====================================================
-- 0) LIMPIEZA SEGURA (DROP IF EXISTS)
-- =====================================================
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Pago CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Reserva CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Habitacion CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Cliente CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Hotel CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
-------------------------------------------------------

-- Usar el esquema HOTEL
ALTER SESSION SET CURRENT_SCHEMA = hotel;

-- =====================================================
-- 1) DDL - CREACIÓN DE TABLAS (versión S6)
-- =====================================================

-- Tabla Hotel
CREATE TABLE Hotel (
    hotel_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR2(100) NOT NULL,
    direccion   VARCHAR2(200),
    categoria   VARCHAR2(50)
);

-- Tabla Habitación (precio entero CLP + estado)
CREATE TABLE Habitacion (
    habitacion_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hotel_id        NUMBER NOT NULL,
    tipo            VARCHAR2(50),
    capacidad       NUMBER,
    precio          NUMBER(10,0) NOT NULL,                    -- CLP sin decimales
    estado          VARCHAR2(15) DEFAULT 'DISPONIBLE' NOT NULL,
    CONSTRAINT fk_habitacion_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id),
    -- Si manejas número de habitación, agrega columna NUMERO y cambia esta UK:
    CONSTRAINT uk_habitacion_num  UNIQUE (hotel_id, tipo, capacidad, precio),
    CONSTRAINT ck_habitacion_estado CHECK (estado IN ('DISPONIBLE','OCUPADA','MANTENCION'))
);

-- Tabla Cliente
CREATE TABLE Cliente (
    cliente_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR2(100) NOT NULL,
    apellido    VARCHAR2(100),
    correo      VARCHAR2(150) UNIQUE,
    telefono    VARCHAR2(20)
);

-- Tabla Reserva (S6: total + estado + validación fechas)
CREATE TABLE Reserva (
    reserva_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id        NUMBER NOT NULL,
    habitacion_id     NUMBER NOT NULL,
    fecha_entrada     DATE   NOT NULL,
    fecha_salida      DATE   NOT NULL,
    cantidad_personas NUMBER,
    total             NUMBER(12,0) NOT NULL,
    estado            VARCHAR2(15) DEFAULT 'PENDIENTE' NOT NULL, -- PENDIENTE | CONFIRMADA | CANCELADA
    created_at        DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_reserva_cliente    FOREIGN KEY (cliente_id)    REFERENCES Cliente(cliente_id),
    CONSTRAINT fk_reserva_habitacion FOREIGN KEY (habitacion_id) REFERENCES Habitacion(habitacion_id),
    CONSTRAINT ck_reserva_fechas     CHECK (fecha_salida > fecha_entrada),
    CONSTRAINT ck_reserva_estado     CHECK (estado IN ('PENDIENTE','CONFIRMADA','CANCELADA'))
);

-- Indices de ayuda
CREATE INDEX ix_reserva_cliente ON Reserva(cliente_id);
CREATE INDEX ix_reserva_hab     ON Reserva(habitacion_id);

-- Tabla Pago (1:1 con Reserva)
CREATE TABLE Pago (
    pago_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reserva_id   NUMBER NOT NULL UNIQUE,
    monto        NUMBER(12,0) NOT NULL,
    fecha_pago   DATE   NOT NULL,
    metodo       VARCHAR2(20) NOT NULL,  -- TARJETA | TRANSFERENCIA | EFECTIVO
    estado       VARCHAR2(15) NOT NULL,  -- APROBADO | RECHAZADO
    transaccion  VARCHAR2(40),
    CONSTRAINT fk_pago_reserva FOREIGN KEY (reserva_id) REFERENCES Reserva(reserva_id),
    CONSTRAINT ck_pago_estado CHECK (estado IN ('APROBADO','RECHAZADO'))
);

-------------------------------------------------------
-- 2) DML - DATOS DE EJEMPLO (reales/depurados)
-------------------------------------------------------

-- Hotel
INSERT INTO Hotel (nombre, direccion, categoria)
VALUES ('Hotel Central', 'Av. Principal 123, Valparaíso', '4 Estrellas');

-- Habitaciones
INSERT INTO Habitacion (hotel_id, tipo, capacidad, precio, estado)
VALUES (1, 'Doble', 2, 55000, 'DISPONIBLE');
INSERT INTO Habitacion (hotel_id, tipo, capacidad, precio, estado)
VALUES (1, 'Suite', 3, 120000, 'DISPONIBLE');
INSERT INTO Habitacion (hotel_id, tipo, capacidad, precio, estado)
VALUES (1, 'Single', 1, 45000, 'MANTENCION');

-- Clientes
INSERT INTO Cliente (nombre, apellido, correo, telefono)
VALUES ('Carolina', 'Rojas', 'caro.rojas@gmail.com', '+56 9 81234567');
INSERT INTO Cliente (nombre, apellido, correo, telefono)
VALUES ('Eduardo', 'Muñoz', 'edu.munoz@gmail.com', '+56 9 92223344');

COMMIT;

-------------------------------------------------------
-- 3) RESERVAS (calcular TOTAL = precio * noches)
-------------------------------------------------------

-- R1: Carolina, Doble, 2 noches
INSERT INTO Reserva (cliente_id, habitacion_id, fecha_entrada, fecha_salida, cantidad_personas, total, estado)
SELECT c.cliente_id, h.habitacion_id,
       DATE '2025-10-10', DATE '2025-10-12', 2,
       h.precio * (DATE '2025-10-12' - DATE '2025-10-10'),
       'PENDIENTE'
FROM Cliente c JOIN Habitacion h ON c.correo='caro.rojas@gmail.com' AND h.tipo='Doble' AND h.estado='DISPONIBLE';

-- R2: Eduardo, Suite, 2 noches
INSERT INTO Reserva (cliente_id, habitacion_id, fecha_entrada, fecha_salida, cantidad_personas, total, estado)
SELECT c.cliente_id, h.habitacion_id,
       DATE '2025-11-01', DATE '2025-11-03', 2,
       h.precio * (DATE '2025-11-03' - DATE '2025-11-01'),
       'PENDIENTE'
FROM Cliente c JOIN Habitacion h ON c.correo='edu.munoz@gmail.com' AND h.tipo='Suite' AND h.estado='DISPONIBLE';

COMMIT;

-------------------------------------------------------
-- 4) PAGOS + ACTUALIZACIÓN DE ESTADO
-------------------------------------------------------

-- Pago APROBADO para R1
INSERT INTO Pago (reserva_id, monto, fecha_pago, metodo, estado, transaccion)
SELECT r.reserva_id, r.total, SYSDATE, 'TARJETA', 'APROBADO', 'TXN-APR-001'
FROM Reserva r
JOIN Cliente c ON r.cliente_id = c.cliente_id
JOIN Habitacion h ON r.habitacion_id = h.habitacion_id
WHERE c.correo='caro.rojas@gmail.com' AND h.tipo='Doble';

UPDATE Reserva
   SET estado = 'CONFIRMADA'
 WHERE reserva_id IN (SELECT reserva_id FROM Pago WHERE estado='APROBADO');

-- Pago RECHAZADO para R2
INSERT INTO Pago (reserva_id, monto, fecha_pago, metodo, estado, transaccion)
SELECT r.reserva_id, r.total, SYSDATE, 'TARJETA', 'RECHAZADO', 'TXN-REJ-002'
FROM Reserva r
JOIN Cliente c ON r.cliente_id = c.cliente_id
JOIN Habitacion h ON r.habitacion_id = h.habitacion_id
WHERE c.correo='edu.munoz@gmail.com' AND h.tipo='Suite';

COMMIT;

-------------------------------------------------------
-- 5) CONSULTAS DE EVIDENCIA (para video/Trello)
-------------------------------------------------------

-- A) Reservas con cliente, habitación, noches, total y estado
SELECT r.reserva_id,
       c.nombre || ' ' || c.apellido AS cliente,
       h.tipo AS habitacion,
       r.fecha_entrada, r.fecha_salida,
       (r.fecha_salida - r.fecha_entrada) AS noches,
       r.total, r.estado
FROM Reserva r
JOIN Cliente c ON r.cliente_id = c.cliente_id
JOIN Habitacion h ON r.habitacion_id = h.habitacion_id
ORDER BY r.reserva_id;

-- B) Pagos y su estado
SELECT p.pago_id, p.reserva_id, p.monto, p.metodo, p.estado, p.transaccion, p.fecha_pago
FROM Pago p
ORDER BY p.pago_id;

-- C) Habitaciones DISPONIBLES para un rango
SELECT h.habitacion_id, h.tipo, h.capacidad, h.precio
FROM Habitacion h
WHERE h.estado='DISPONIBLE'
AND NOT EXISTS (
  SELECT 1
  FROM Reserva r
  WHERE r.habitacion_id = h.habitacion_id
    AND r.estado IN ('PENDIENTE','CONFIRMADA')
    AND (DATE '2025-10-11' < r.fecha_salida AND DATE '2025-10-13' > r.fecha_entrada)
)
ORDER BY h.tipo;

-- D) Ingresos confirmados por mes
SELECT TO_CHAR(r.fecha_entrada,'YYYY-MM') AS periodo,
       SUM(r.total) AS ingresos_confirmados
FROM Reserva r
WHERE r.estado='CONFIRMADA'
GROUP BY TO_CHAR(r.fecha_entrada,'YYYY-MM')
ORDER BY periodo;

-------------------------------------------------------
-- 6) CRUD DEMO (para evidenciar operaciones)
-------------------------------------------------------

-- CREATE: nueva reserva PENDIENTE (Eduardo, Doble, 1 noche)
INSERT INTO Reserva (cliente_id, habitacion_id, fecha_entrada, fecha_salida, cantidad_personas, total, estado)
SELECT c.cliente_id, h.habitacion_id,
       DATE '2025-10-20', DATE '2025-10-21', 2,
       h.precio * 1, 'PENDIENTE'
FROM Cliente c JOIN Habitacion h
ON c.correo='edu.munoz@gmail.com' AND h.tipo='Doble';

-- READ: ver última reserva de Eduardo
SELECT * FROM Reserva r
WHERE r.cliente_id = (SELECT cliente_id FROM Cliente WHERE correo='edu.munoz@gmail.com')
ORDER BY r.reserva_id DESC FETCH FIRST 1 ROWS ONLY;

-- UPDATE: cancelar la última reserva de Eduardo
UPDATE Reserva r
   SET r.estado='CANCELADA'
 WHERE r.reserva_id = (
   SELECT MAX(r2.reserva_id) FROM Reserva r2
   JOIN Cliente c ON r2.cliente_id=c.cliente_id
   WHERE c.correo='edu.munoz@gmail.com'
 );

-- DELETE: borrar un pago RECHAZADO de prueba (si existiera duplicado)
DELETE FROM Pago WHERE estado='RECHAZADO' AND ROWNUM = 1;

COMMIT;

-------------------------------------------------------
-- 7) VERIFICACIÓN DE TABLAS
-------------------------------------------------------
SELECT table_name FROM user_tables
WHERE table_name IN ('HOTEL','HABITACION','CLIENTE','RESERVA','PAGO')
ORDER BY table_name;
