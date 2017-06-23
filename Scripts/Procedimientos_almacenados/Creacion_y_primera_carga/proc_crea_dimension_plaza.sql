DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_plaza`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_plaza`(IN flag bit(1), IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/* 
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS plaza;
	END IF;

	CREATE TABLE IF NOT EXISTS plaza (
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

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".plaza(plaza_nk, nombre_plaza, numero_plaza, version_actual_flag, ultima_actualizacion) 
		SELECT  id,
		IF(nombre IS NULL OR  nombre = '', 'Desconocido', nombre) AS nombre, 
		IF(numero IS NULL, 0, numero) AS numero, 
		'Actual', 
		CURDATE()
		FROM ", baseDatosProd, ".plaza 
		WHERE empresa = ", idEmpresa, ";");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    IF (SELECT COUNT(*) FROM plaza WHERE plaza_key = -1) = 0 THEN 
	    INSERT INTO plaza(plaza_key, plaza_nk, nombre_plaza, numero_plaza) 
		VALUES(-1, -1, 'Desconocido', 0);
	END IF;
	
	CALL proc_inserta_registro_historico_etl(idEmpresa, fechaTiempoETL, 'plaza', (SELECT COUNT(*) FROM plaza));
END
$$