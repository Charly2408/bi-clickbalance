DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_agente`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_agente`(IN flag bit(1),  IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS agente;
	END IF;

	CREATE TABLE IF NOT EXISTS agente (
		agente_key INT NOT NULL AUTO_INCREMENT,
		agente_nk BIGINT(20) NOT NULL,
		nombre_agente VARCHAR(245) NOT NULL DEFAULT 'Desconocido',
		tipo_agente VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		estatus_agente VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		sexo VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT '1901-01-01',
		PRIMARY KEY (agente_key),
		UNIQUE INDEX ix_agente_key (agente_key ASC),
		INDEX ix_agente_nk (agente_nk ASC))
	ENGINE = MyISAM;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".agente(agente_nk, nombre_agente, tipo_agente, estatus_agente, sexo, version_actual_flag, ultima_actualizacion) 
		select id, 
		CASE regimen 
            WHEN 'PF' THEN IF((nombre IS NULL OR nombre = '') AND (apellido_paterno IS NULL OR apellido_paterno = '') AND (apellido_materno IS NULL OR apellido_materno = ''), 'Desconocido', CONCAT(nombre, ' ', apellido_paterno, ' ', apellido_materno)) 
            WHEN 'PM' THEN IF(razon_social IS NULL OR razon_social = '', 'Desconocido', razon_social)
            ELSE 'Desconocido' 
        END AS nombre_o_razon_social,
		CASE tipo_agente 
			WHEN 'E' THEN 'Empleado' 
			WHEN 'U' THEN 'Usuario' 
			WHEN 'X' THEN 'Externo' 
			ELSE 'Desconocido' 
		END AS tipo_agente, 
		CASE estatus_agente 
            WHEN 'A' THEN 'Activo' 
            WHEN 'S' THEN 'Suspendido' 
            WHEN 'C' THEN 'Cancelado' 
            WHEN 'B' THEN 'Usuario' 
            ELSE 'Desconocido' 
        END AS estatus_agente, 
        CASE sexo 
        	WHEN 'M' THEN 'Masculino'
        	WHEN 'F' THEN 'Femenino'
        	ELSE 'Desconocido'
        END AS sexo, 
        'Actual', 
        CURDATE() 
		FROM ", baseDatosProd, ".asociado
		WHERE es_agente = 1 AND empresa = ", idEmpresa," AND created_at <= '", fechaTiempoETL, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    IF (SELECT COUNT(*) FROM agente WHERE agente_key = -1) = 0 THEN 
		INSERT INTO agente(agente_key, agente_nk, nombre_agente, tipo_agente, estatus_agente, sexo) 
		VALUES(-1, -1, 'Desconocido', 'Desconocido', 'Desconocido', 'Desconocido');
	END IF;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'agente', (SELECT COUNT(*) FROM agente));
END
$$