# Hotel – Semana 6

Este repositorio contiene la **base de datos integrada** del sistema de reservas de hotel, correspondiente a la **Semana 6 de Ingeniería de Software**.

## Contenido
- `Hotel_S6.sql` → Script con:
  - Creación de tablas (`Hotel`, `Habitacion`, `Cliente`, `Reserva`, `Pago`).
  - Restricciones y validaciones (`estado`, fechas correctas).
  - Datos de ejemplo.
  - Consultas de evidencia.
  - CRUD (Create, Read, Update, Delete).

## Ejecución
1. Abrir Oracle SQL Developer o SQL*Plus.
2. Cambiar al esquema:
   ```sql
   ALTER SESSION SET CURRENT_SCHEMA = hotel;

	3.	Ejecutar el script Hotel_S6.sql por bloques.
	4.	Revisar las consultas incluidas para mostrar evidencia en video.

Evidencias

El script permite demostrar:
	•	Reservas con noches, total y estado.
	•	Pagos con estado APROBADO / RECHAZADO.
	•	Habitaciones disponibles en un rango de fechas.
	•	Reporte de ingresos confirmados por mes.
	•	Operaciones CRUD completas.

Los UML, Mockups y DOD se entregan como evidencia en Trello y AVA (no en este repo)

