DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_empresa`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_empresa`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_empresa

	CREATE TABLE IF NOT EXISTS tmp_empresa (
		empresa_key INT NOT NULL AUTO_INCREMENT,
		empresa_nk BIGINT(20) NOT NULL,
		razon_social VARCHAR(245) NOT NULL DEFAULT 'Desconocida',
		nombre_comercial VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
		regimen VARCHAR(15) NOT NULL DEFAULT 'Desconocido',
		sector VARCHAR(16) NOT NULL DEFAULT 'Desconocido',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01,
		PRIMARY KEY (empresa_key),
		UNIQUE INDEX ix_empresa_key (empresa_key ASC),
		INDEX ix_empresa_nk (empresa_nk ASC))
	ENGINE = MyISAM;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".empresa(empresa_nk, razon_social, nombre_comercial, regimen, sector, version_actual_flag, ultima_actualizacion) 
		SELECT id,
		IF(razon_social IS NULL OR razon_social = '', 'Desconocida', razon_social) AS razon_social, 
		IF(nombre_comercial IS NULL OR  nombre_comercial = '', 'Desconocido', nombre_comercial) AS nombre_comercial, 
		CASE regimen 
            WHEN 'PF' THEN 'PERSONA FISICA'
            WHEN 'PM' THEN 'PERSONA MORAL'
            ELSE 'Desconocido' 
        END AS regimen_fiscal,
        CASE sector 
            WHEN 1 THEN 'Industria'
            WHEN 2 THEN 'Comercio'
            WHEN 3 THEN 'Servicios'
            WHEN 4 THEN 'Personal'
            WHEN 5 THEN 'Educativo'
            WHEN 6 THEN 'Asociacion Civil'
            ELSE 'Desconocido' 
        END AS sector,
		'Actual', 
        CURDATE() 
		FROM ", baseDatosProd, ".empresa
		WHERE id = ", idEmpresa, " AND (created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "');");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_empresa_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_empresa_a_historico
	SELECT e.empresa_key, e.empresa_nk
    FROM tmp_empresa AS te 
    	INNER JOIN empresa AS e ON (te.empresa_nk = e.empresa_nk)
    WHERE e.version_actual_flag = 'Actual' AND (e.razon_social <> te.razon_social OR e.nombre_comercial <> te.nombre_comercial OR e.regimen <> te.regimen OR e.sector <> te.sector);

	INSERT INTO empresa(empresa_nk, razon_social, nombre_comercial, regimen, sector, version_actual_flag, ultima_actualizacion)
	SELECT te.empresa_nk, te.razon_social, te.nombre_comercial, te.regimen, te.sector, te.version_actual_flag, te.ultima_actualizacion
    FROM tmp_empresa AS te 
    	INNER JOIN empresa AS e ON (te.empresa_nk = e.empresa_nk)
    WHERE e.version_actual_flag = 'Actual' AND (e.razon_social <> te.razon_social OR e.nombre_comercial <> te.nombre_comercial OR e.regimen <> te.regimen OR e.sector <> te.sector);

    UPDATE empresa AS e
    	INNER JOIN tmp_empresa_a_historico AS teh ON (e.empresa_key = teh.empresa_key)
    SET e.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_empresa_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_empresa_version_actual
    SELECT e.empresa_key AS empresa_key_actual, teh.empresa_key AS empresa_key_historica
    FROM empresa AS e
    	INNER JOIN tmp_empresa_a_historico AS teh ON (e.empresa_nk = teh.empresa_nk)
    WHERE e.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_empresa_version_actual AS teva ON (fv.empresa_key = teva.empresa_key_historica)
    SET fv.empresa_key = teva.empresa_key_historica;

     -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO empresa(empresa_nk, razon_social, nombre_comercial, regimen, sector, version_actual_flag, ultima_actualizacion)
    SELECT te.empresa_nk, te.razon_social, te.nombre_comercial, te.regimen, te.sector, te.version_actual_flag, te.ultima_actualizacion
    FROM tmp_empresa as te 
    	LEFT JOIN empresa as e ON (te.empresa_nk = e.empresa_nk)
    WHERE e.empresa_nk IS NULL;

    DROP TABLE IF EXISTS tmp_empresa;
    DROP TABLE IF EXISTS tmp_empresa_a_historico;
    DROP TABLE IF EXISTS tmp_empresa_version_actual;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'empresa', (SELECT COUNT(*) FROM empresa));
END
$$