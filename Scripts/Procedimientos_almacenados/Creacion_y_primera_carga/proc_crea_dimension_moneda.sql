DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_moneda`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_moneda`(IN flag bit(1), IN baseDatosProd varchar(50), IN baseDatosBI varchar(50))
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos
	Si flag = 1, Crea la tabla sino existe y la llena con los datos
*/
BEGIN
	DECLARE fechaTiempoETL DATETIME;
    SET fechaTiempoETL = NOW();
	
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS moneda;
	END IF;

	CREATE TABLE IF NOT EXISTS moneda (
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

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".moneda(moneda_nk, nombre_moneda, abreviatura, version_actual_flag, ultima_actualizacion) 
		SELECT  id, 
		IF(nombre_moneda IS NULL OR nombre_moneda = '', 'Desconocido', nombre_moneda) AS nom_moneda, 
		IF(abreviatura IS NULL OR  abreviatura = '', 'Desconocida', abreviatura) AS abr_moneda, 
		'Actual', 
        CURDATE() 
		FROM ", baseDatosProd, ".moneda;");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    IF (SELECT COUNT(*) FROM moneda WHERE moneda_key = -1) = 0 THEN 
	    INSERT INTO .moneda(moneda_key, moneda_nk, nombre_moneda, abreviatura) 
		VALUES(-1, -1, 'Desconocido', 'Desconocida');
	END IF;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'moneda', (SELECT COUNT(*) FROM moneda));
END
$$