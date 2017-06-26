DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_registro_historico_etl`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_registro_historico_etl`(IN flag BIT(1), IN idEmpresa BIGINT(20), IN ultimaActualizacion DATETIME, IN nombreTabla VARCHAR(50), IN numRegistros INT)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea nuevamente e inserta el registro.
	Si flag = 1, Crea la tabla sino existe e inserta el registro.
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS historico_etl;
	END IF;

	CREATE TABLE IF NOT EXISTS historico_etl (
		historico_etl_id INT NOT NULL AUTO_INCREMENT,
		empresa_cb_id BIGINT(20) NOT NULL,
		ultima_actualizacion DATETIME NOT NULL,
		nombre_dimension_o_hecho VARCHAR(100) NOT NULL DEFAULT 'Desconocida',
		numero_registros INT NOT NULL,
		PRIMARY KEY (historico_etl_id),
		UNIQUE INDEX ix_historico_etl_id (historico_etl_id ASC))
	ENGINE = MyISAM;

	IF flag = 1 THEN 
		INSERT INTO historico_etl(empresa_cb_id, ultima_actualizacion, nombre_dimension_o_hecho, numero_registros) 
		VALUES (idEmpresa, ultimaActualizacion, nombreTabla, numRegistros);
	END IF;
END
$$