DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_empresa`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_empresa`(IN flag bit(1), IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS empresa;
	END IF;

	CREATE TABLE IF NOT EXISTS empresa (
		empresa_key INT NOT NULL AUTO_INCREMENT,
		empresa_nk BIGINT(20) NOT NULL,
		razon_social VARCHAR(245) NOT NULL DEFAULT 'Desconocida',
		nombre_comercial VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
		regimen VARCHAR(15) NOT NULL DEFAULT 'Desconocido',
		sector VARCHAR(16) NOT NULL DEFAULT 'Desconocido',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT '1901-01-01',
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
		WHERE id = ", idEmpresa, " AND created_at <= '", fechaTiempoETL, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    IF (SELECT COUNT(*) FROM empresa WHERE empresa_key = -1) = 0 THEN 
   		INSERT INTO empresa(empresa_key, empresa_nk, razon_social, nombre_comercial, regimen, sector) 
		VALUES(-1, -1, 'Desconocida', 'Desconocido', 'Desconocido', 'Desconocido');
	END IF;
	
	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'empresa', (SELECT COUNT(*) FROM empresa));
END
$$