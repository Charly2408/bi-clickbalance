DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_agente`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_agente`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_agente;

	CREATE TABLE IF NOT EXISTS tmp_agente (
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

	CALL proc_consulta_registro_historico_etl(idEmpresa, 'agente', @ultimaAct);

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_agente(agente_nk, nombre_agente, tipo_agente, estatus_agente, sexo, version_actual_flag, ultima_actualizacion) 
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
		WHERE es_agente = 1 AND empresa = ", idEmpresa," AND (created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "') AND created_at <= '", fechaTiempoETL, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 1
	UPDATE agente AS a  
		INNER JOIN tmp_agente as ta ON (ta.agente_nk = a.agente_nk)
	SET a.sexo = ta.sexo,
		a.ultima_actualizacion = IF(a.version_actual_flag = 'Actual', ta.ultima_actualizacion, a.ultima_actualizacion)
	WHERE a.sexo <> ta.sexo;

	-- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_agente_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_agente_a_historico
	SELECT a.agente_key, a.agente_nk
    FROM tmp_agente as ta 
    	INNER JOIN agente as a ON (ta.agente_nk = a.agente_nk)
    WHERE a.version_actual_flag = 'Actual' AND (a.nombre_agente <> ta.nombre_agente OR a.tipo_agente <> ta.tipo_agente OR a.estatus_agente <> ta.estatus_agente);

	INSERT INTO agente(agente_nk, nombre_agente, tipo_agente, estatus_agente, sexo, version_actual_flag, ultima_actualizacion)
	SELECT ta.agente_nk, ta.nombre_agente, ta.tipo_agente, ta.estatus_agente, ta.sexo, ta.version_actual_flag, ta.ultima_actualizacion
    FROM tmp_agente as ta 
    	INNER JOIN agente as a ON (ta.agente_nk = a.agente_nk)
    WHERE a.version_actual_flag = 'Actual' AND (a.nombre_agente <> ta.nombre_agente OR a.tipo_agente <> ta.tipo_agente OR a.estatus_agente <> ta.estatus_agente);

    UPDATE agente AS a
    	INNER JOIN tmp_agente_a_historico AS tah ON (a.agente_key = tah.agente_key)
    SET a.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_agente_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_agente_version_actual
    SELECT a.agente_key AS agente_key_actual, tah.agente_key AS agente_key_historica
    FROM agente AS a
    	INNER JOIN tmp_agente_a_historico AS tah ON (a.agente_nk = tah.agente_nk)
    WHERE a.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_agente_version_actual AS tava ON (fv.agente_key = tava.agente_key_historica)
    SET fv.agente_key = tava.agente_key_actual;

    -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO agente(agente_nk, nombre_agente, tipo_agente, estatus_agente, sexo, version_actual_flag, ultima_actualizacion) 
    SELECT ta.agente_nk, ta.nombre_agente, ta.tipo_agente, ta.estatus_agente, ta.sexo, ta.version_actual_flag, ta.ultima_actualizacion
    FROM tmp_agente as ta 
    	LEFT JOIN agente as a ON (ta.agente_nk = a.agente_nk)
    WHERE a.agente_nk IS NULL;

    DROP TABLE IF EXISTS tmp_agente;
    DROP TABLE IF EXISTS tmp_agente_a_historico;
    DROP TABLE IF EXISTS tmp_agente_version_actual;

    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'agente', (SELECT COUNT(*) FROM agente));
END
$$