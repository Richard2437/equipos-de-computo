-- Versión resumida (mySQL)

CREATE TABLE persona (
    id_persona  SERIAL PRIMARY KEY,
    documento   VARCHAR(20)  NOT NULL UNIQUE,
    nombres     VARCHAR(80)  NOT NULL,
    apellidos   VARCHAR(80)  NOT NULL,
    rol         VARCHAR(10)  NOT NULL CHECK (rol IN ('ESTUDIANTE','PROFESOR')),
    correo      VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE equipo (
    id_equipo         SERIAL PRIMARY KEY,
    serial            VARCHAR(50) NOT NULL UNIQUE,
    marca             VARCHAR(50) NOT NULL,
    modelo            VARCHAR(50) NOT NULL,
    tipo_propiedad    VARCHAR(12) NOT NULL CHECK (tipo_propiedad IN ('UNIVERSIDAD','PERSONAL')),
    id_propietario    INT REFERENCES persona(id_persona),
    codigo_inventario VARCHAR(30) UNIQUE,
    CHECK ((tipo_propiedad = 'UNIVERSIDAD' AND id_propietario IS NULL AND codigo_inventario IS NOT NULL)
        OR (tipo_propiedad = 'PERSONAL'    AND id_propietario IS NOT NULL AND codigo_inventario IS NULL))
);

CREATE TABLE prestamo (
    id_prestamo               SERIAL PRIMARY KEY,
    id_equipo                 INT  NOT NULL REFERENCES equipo(id_equipo),
    id_persona                INT  NOT NULL REFERENCES persona(id_persona),
    fecha_entrega             DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_devolucion_esperada DATE NOT NULL CHECK (fecha_devolucion_esperada >= fecha_entrega),
    fecha_devolucion_real     DATE CHECK (fecha_devolucion_real >= fecha_entrega),
    estado_entrega            VARCHAR(20) NOT NULL CHECK (estado_entrega IN ('NUEVO','BUENO','REGULAR','CON DAÑOS')),
    estado_devolucion         VARCHAR(20) CHECK (estado_devolucion IN ('NUEVO','BUENO','REGULAR','CON DAÑOS')),
    CHECK ((fecha_devolucion_real IS NULL) = (estado_devolucion IS NULL))
);

-- Un equipo solo puede tener un préstamo abierto
CREATE UNIQUE INDEX ux_prestamo_abierto ON prestamo(id_equipo) WHERE fecha_devolucion_real IS NULL;

-- Datos de prueba
INSERT INTO persona (documento, nombres, apellidos, rol, correo) VALUES
 ('1001','Laura','Gómez','ESTUDIANTE','laura@uni.edu'),
 ('2001','Marta','Pérez','PROFESOR','marta@uni.edu');
INSERT INTO equipo (serial, marca, modelo, tipo_propiedad, id_propietario, codigo_inventario) VALUES
 ('U-001','Dell','Latitude','UNIVERSIDAD',NULL,'INV-1'),
 ('U-002','Lenovo','ThinkPad','UNIVERSIDAD',NULL,'INV-2'),
 ('P-001','Asus','VivoBook','PERSONAL',1,NULL);
INSERT INTO prestamo (id_equipo, id_persona, fecha_entrega, fecha_devolucion_esperada, estado_entrega) VALUES
 (1, 2, CURRENT_DATE - 10, CURRENT_DATE - 3, 'BUENO');

-- Consultas
-- Equipos prestados actualmente
SELECT e.codigo_inventario, p.nombres, pr.fecha_entrega, pr.fecha_devolucion_esperada
FROM prestamo pr JOIN equipo e USING (id_equipo) JOIN persona p USING (id_persona)
WHERE pr.fecha_devolucion_real IS NULL;

-- Personas con equipo por más de una semana
SELECT p.nombres, e.codigo_inventario, CURRENT_DATE - pr.fecha_entrega AS dias
FROM prestamo pr JOIN equipo e USING (id_equipo) JOIN persona p USING (id_persona)
WHERE pr.fecha_devolucion_real IS NULL AND CURRENT_DATE - pr.fecha_entrega > 7;

-- Equipos de la universidad disponibles
SELECT * FROM equipo e
WHERE tipo_propiedad = 'UNIVERSIDAD'
  AND NOT EXISTS (SELECT 1 FROM prestamo pr WHERE pr.id_equipo = e.id_equipo AND pr.fecha_devolucion_real IS NULL);-- Versión resumida (MySQL 8.0.16 o superior)

CREATE DATABASE IF NOT EXISTS control_equipos;
USE control_equipos;

CREATE TABLE persona (
    id_persona  INT AUTO_INCREMENT PRIMARY KEY,
    documento   VARCHAR(20)  NOT NULL UNIQUE,
    nombres     VARCHAR(80)  NOT NULL,
    apellidos   VARCHAR(80)  NOT NULL,
    rol         VARCHAR(10)  NOT NULL,
    correo      VARCHAR(120) NOT NULL UNIQUE,
    CONSTRAINT ck_rol CHECK (rol IN ('ESTUDIANTE','PROFESOR'))
);

CREATE TABLE equipo (
    id_equipo         INT AUTO_INCREMENT PRIMARY KEY,
    serial            VARCHAR(50) NOT NULL UNIQUE,
    marca             VARCHAR(50) NOT NULL,
    modelo            VARCHAR(50) NOT NULL,
    tipo_propiedad    VARCHAR(12) NOT NULL,
    id_propietario    INT NULL,
    codigo_inventario VARCHAR(30) NULL UNIQUE,
    FOREIGN KEY (id_propietario) REFERENCES persona(id_persona),
    CONSTRAINT ck_propiedad CHECK (
        (tipo_propiedad = 'UNIVERSIDAD' AND id_propietario IS NULL AND codigo_inventario IS NOT NULL)
     OR (tipo_propiedad = 'PERSONAL'    AND id_propietario IS NOT NULL AND codigo_inventario IS NULL))
);

CREATE TABLE prestamo (
    id_prestamo               INT AUTO_INCREMENT PRIMARY KEY,
    id_equipo                 INT  NOT NULL,
    id_persona                INT  NOT NULL,
    fecha_entrega             DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_devolucion_esperada DATE NOT NULL,
    fecha_devolucion_real     DATE NULL,
    estado_entrega            VARCHAR(20) NOT NULL,
    estado_devolucion         VARCHAR(20) NULL,
    -- MySQL no tiene índices parciales: esta columna vale id_equipo solo si el préstamo
    -- está abierto; al ser UNIQUE, impide dos préstamos abiertos del mismo equipo.
    equipo_abierto INT GENERATED ALWAYS AS (IF(fecha_devolucion_real IS NULL, id_equipo, NULL)) STORED,
    UNIQUE KEY ux_prestamo_abierto (equipo_abierto),
    FOREIGN KEY (id_equipo)  REFERENCES equipo(id_equipo),
    FOREIGN KEY (id_persona) REFERENCES persona(id_persona),
    CONSTRAINT ck_esperada CHECK (fecha_devolucion_esperada >= fecha_entrega),
    CONSTRAINT ck_real     CHECK (fecha_devolucion_real IS NULL OR fecha_devolucion_real >= fecha_entrega),
    CONSTRAINT ck_est_ent  CHECK (estado_entrega IN ('NUEVO','BUENO','REGULAR','CON DAÑOS')),
    CONSTRAINT ck_est_dev  CHECK (estado_devolucion IS NULL OR estado_devolucion IN ('NUEVO','BUENO','REGULAR','CON DAÑOS')),
    CONSTRAINT ck_dev_completa CHECK ((fecha_devolucion_real IS NULL) = (estado_devolucion IS NULL))
);

-- Datos de prueba
INSERT INTO persona (documento, nombres, apellidos, rol, correo) VALUES
 ('1001','Laura','Gómez','ESTUDIANTE','laura@uni.edu'),
 ('2001','Marta','Pérez','PROFESOR','marta@uni.edu');

INSERT INTO equipo (serial, marca, modelo, tipo_propiedad, id_propietario, codigo_inventario) VALUES
 ('U-001','Dell','Latitude','UNIVERSIDAD',NULL,'INV-1'),
 ('U-002','Lenovo','ThinkPad','UNIVERSIDAD',NULL,'INV-2'),
 ('P-001','Asus','VivoBook','PERSONAL',1,NULL);

INSERT INTO prestamo (id_equipo, id_persona, fecha_entrega, fecha_devolucion_esperada, estado_entrega) VALUES
 (1, 2, CURDATE() - INTERVAL 10 DAY, CURDATE() - INTERVAL 3 DAY, 'BUENO');

-- Consultas
-- 1. Equipos prestados actualmente
SELECT e.codigo_inventario, p.nombres, pr.fecha_entrega, pr.fecha_devolucion_esperada
FROM prestamo pr
JOIN equipo e  ON e.id_equipo  = pr.id_equipo
JOIN persona p ON p.id_persona = pr.id_persona
WHERE pr.fecha_devolucion_real IS NULL;

-- 2. Personas con equipo por más de una semana
SELECT p.nombres, e.codigo_inventario, DATEDIFF(CURDATE(), pr.fecha_entrega) AS dias
FROM prestamo pr
JOIN equipo e  ON e.id_equipo  = pr.id_equipo
JOIN persona p ON p.id_persona = pr.id_persona
WHERE pr.fecha_devolucion_real IS NULL
  AND DATEDIFF(CURDATE(), pr.fecha_entrega) > 7;

-- 3. Equipos de la universidad disponibles
SELECT e.*
FROM equipo e
WHERE e.tipo_propiedad = 'UNIVERSIDAD'
  AND NOT EXISTS (SELECT 1 FROM prestamo pr
                  WHERE pr.id_equipo = e.id_equipo AND pr.fecha_devolucion_real IS NULL);