DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_plaza`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_plaza`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_plaza;

	CREATE TABLE IF NOT EXISTS tmp_plaza (
		plaza_key INT NOT NULL AUTO_INCREMENT,
		plaza_nk BIGINT(20) NOT NULL,
		nombre_plaza VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
		numero_plaza INT NOT NULL,
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01,
		PRIMARY KEY (plaza_key),
		UNIQUE INDEX ix_plaza_key (plaza_key ASC),
		INDEX ix_plaza_nk (plaza_nk ASC))
	ENGINE = MyISAM;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_plaza(plaza_nk, nombre_plaza, numero_plaza, version_actual_flag, ultima_actualizacion) 
		SELECT  id,
		IF(nombre IS NULL OR  nombre = '', 'Desconocido', nombre) AS nombre, 
		IF(numero IS NULL, 0, numero) AS numero, 
		'Actual', 
		CURDATE()
		FROM ", baseDatosProd, ".plaza 
		WHERE empresa = ", idEmpresa, " AND (created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "');");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_plaza_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_plaza_a_historico
	SELECT p.plaza_key, p.plaza_nk
    FROM tmp_plaza AS tp 
    	INNER JOIN plaza AS p ON (tp.plaza_nk = p.plaza_nk)
    WHERE p.version_actual_flag = 'Actual' AND (p.nombre_plaza <> tp.nombre_plaza OR p.numero_plaza <> tp.numero_plaza);

	INSERT INTO plaza(plaza_nk, nombre_plaza, numero_plaza, version_actual_flag, ultima_actualizacion)
	SELECT tp.plaza_nk, tp.nombre_plaza, tp.numero_plaza, tp.version_actual_flag, tp.ultima_actualizacion
    FROM tmp_plaza AS tp 
    	INNER JOIN plaza AS p ON (tp.plaza_nk = p.plaza_nk)
    WHERE p.version_actual_flag = 'Actual' AND (p.nombre_plaza <> tp.nombre_plaza OR p.numero_plaza <> tp.numero_plaza);

    UPDATE plaza AS p
    	INNER JOIN tmp_plaza_a_historico AS tph ON (p.plaza_key = tph.plaza_key)
    SET p.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_plaza_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_plaza_version_actual
    SELECT p.plaza_key AS plaza_key_actual, tph.plaza_key AS plaza_key_historica
    FROM plaza AS m
    	INNER JOIN tmp_plaza_a_historico AS tph ON (p.plaza_nk = tph.plaza_nk)
    WHERE p.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_plaza_version_actual AS tpva ON (fv.plaza_key = tpva.plaza_key_historica)
    SET fv.plaza_key = tpva.plaza_key_historica;

    -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO plaza(plaza_nk, nombre_plaza, numero_plaza, version_actual_flag, ultima_actualizacion) 
    SELECT tp.plaza_nk, tp.nombre_plaza, tp.numero_plaza, tp.version_actual_flag, tp.ultima_actualizacion
    FROM tmp_plaza as tp 
    	LEFT JOIN plaza as p ON (tp.plaza_nk = p.plaza_nk)
    WHERE p.plaza_nk IS NULL;

    DROP TABLE IF EXISTS tmp_plaza;
    DROP TABLE IF EXISTS tmp_plaza_a_historico;
    DROP TABLE IF EXISTS tmp_plaza_version_actual;
	
	CALL proc_inserta_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'plaza', (SELECT COUNT(*) FROM plaza));
END
$$