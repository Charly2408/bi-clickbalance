DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_moneda`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_moneda`(IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_moneda;

	CREATE TABLE IF NOT EXISTS tmp_moneda (
		moneda_key INT NOT NULL AUTO_INCREMENT, 
		moneda_nk INT NOT NULL, 
		nombre_moneda VARCHAR(50) NOT NULL DEFAULT 'Desconocido', 
		abreviatura VARCHAR(11) NOT NULL DEFAULT 'Desconocida',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual', 
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01, 
		PRIMARY KEY (moneda_key), 
		UNIQUE INDEX ix_moneda_key (moneda_key ASC), 
		INDEX ix_moneda_nk (moneda_nk ASC)) 
	ENGINE = MyISAM;

    CALL proc_consulta_registro_historico_etl(0, 'moneda', @ultimaAct);

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_moneda(moneda_nk, nombre_moneda, abreviatura, version_actual_flag, ultima_actualizacion) 
		SELECT  id, 
		IF(nombre_moneda IS NULL OR nombre_moneda = '', 'Desconocido', nombre_moneda) AS nom_moneda, 
		IF(abreviatura IS NULL OR  abreviatura = '', 'Desconocida', abreviatura) AS abr_moneda, 
		'Actual', 
        CURDATE() 
		FROM ", baseDatosProd, ".moneda
		WHERE created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_moneda_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_moneda_a_historico
	SELECT m.moneda_key, m.moneda_nk
    FROM tmp_moneda AS tm 
    	INNER JOIN moneda AS m ON (tm.moneda_nk = m.moneda_nk)
    WHERE m.version_actual_flag = 'Actual' AND (m.nombre_moneda <> tm.nombre_moneda OR m.abreviatura <> tm.abreviatura);

	INSERT INTO moneda(moneda_nk, nombre_moneda, abreviatura, version_actual_flag, ultima_actualizacion) 
	SELECT tm.moneda_nk, tm.nombre_moneda, tm.abreviatura, tm.version_actual_flag, tm.ultima_actualizacion
    FROM tmp_moneda AS tm 
    	INNER JOIN moneda AS m ON (tm.moneda_nk = m.moneda_nk)
    WHERE m.version_actual_flag = 'Actual' AND (m.nombre_moneda <> tm.nombre_moneda OR m.abreviatura <> tm.abreviatura);

    UPDATE moneda AS m
    	INNER JOIN tmp_moneda_a_historico AS tmh ON (m.moneda_key = tmh.moneda_key)
    SET m.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_moneda_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_moneda_version_actual
    SELECT m.moneda_key AS moneda_key_actual, tmh.moneda_key AS moneda_key_historica
    FROM moneda AS m
    	INNER JOIN tmp_moneda_a_historico AS tmh ON (m.moneda_nk = tmh.moneda_nk)
    WHERE m.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_moneda_version_actual AS tmva ON (fv.moneda_key = tmva.moneda_key_historica)
    SET fv.moneda_key = tmva.moneda_key_actual;

    -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO moneda(moneda_nk, nombre_moneda, abreviatura, version_actual_flag, ultima_actualizacion) 
    SELECT tm.moneda_nk, tm.nombre_moneda, tm.abreviatura, tm.version_actual_flag, tm.ultima_actualizacion
    FROM tmp_moneda as tm 
    	LEFT JOIN moneda as m ON (tm.moneda_nk = m.moneda_nk)
    WHERE m.moneda_nk IS NULL;

    DROP TABLE IF EXISTS tmp_moneda;
    DROP TABLE IF EXISTS tmp_moneda_a_historico;
    DROP TABLE IF EXISTS tmp_moneda_version_actual;

	CALL proc_crea_registro_historico_etl(1, 0, fechaTiempoETL, 'moneda', (SELECT COUNT(*) FROM moneda));
END
$$