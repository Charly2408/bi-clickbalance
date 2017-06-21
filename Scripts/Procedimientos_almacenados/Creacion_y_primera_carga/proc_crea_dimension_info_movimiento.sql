DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_info_movimiento`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_info_movimiento`(IN flag bit(1),  IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50))
/*
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	DECLARE fechaTiempoETL DATETIME;
	DECLARE idTipoVenta BIGINT(20);
	DECLARE vTipoVenta VARCHAR(50);
	DECLARE codigoEstatus VARCHAR(1);
	DECLARE vEstatus VARCHAR(11);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE curTipoVenta CURSOR FOR SELECT id, nombre FROM tmp_tipoventa_bi;
    DECLARE curEstatus CURSOR FOR SELECT codigo_estatus, estatus FROM tmp_estatus_bi;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET fechaTiempoETL = NOW();

	IF flag = 0 THEN 
		DROP TABLE IF EXISTS tipo_movimiento;
	END IF;

	CREATE TABLE tmp_estatus_bi (
		codigo_estatus VARCHAR(1) NOT NULL,
		estatus VARCHAR(11) NOT NULL);
	
	INSERT INTO tmp_estatus_bi (codigo_estatus, estatus)
	VALUES 
	('0', 'Terminado'),
	('3', 'Cancelado'),
	('', 'Desconocido');

	DROP TABLE IF EXISTS tmp_tipoventa_bi;

	SET @query = CONCAT("CREATE TABLE tmp_tipoventa_bi 
		SELECT id, 
		IF(descripcion IS NULL OR descripcion = '', 'Desconocido', descripcion) as nombre, 
    	FROM ", baseDatosProd, ".tipo_venta 
    	WHERE empresa = ", idEmpresa, " AND es_venta = 1;");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	CREATE TABLE IF NOT EXISTS info_movimiento (
		info_movimiento_key INT NOT NULL AUTO_INCREMENT,
		tipo_movimiento_nk BIGINT(20) NOT NULL,
		grupo VARCHAR(20) NOT NULL DEFAULT 'Desconocido',
		nombre_movimiento VARCHAR(65) NOT NULL DEFAULT 'Desconocido',
		estatus VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		codigo_estatus VARCHAR(1) NOT NULL,
		naturaleza TINYINT(1) NOT NULL,
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01,
		PRIMARY KEY (info_movimiento_key),
		UNIQUE INDEX ix_tipo_movimiento_key (info_movimiento_key ASC),
		INDEX ix_tipo_movimiento_nk (tipo_movimiento_nk ASC),
		INDEX ix_codigo_estatus (codigo_estatus ASC))
	ENGINE = MyISAM;

	OPEN curTipoVenta;
	tipoventa_loop: LOOP
		FETCH curTipoVenta INTO idTipoVenta, vTipoVenta;
		IF done THEN
			SET done = FALSE;
			LEAVE tipoventa_loop;
		END IF;
		OPEN curEstatus;
		estatus_loop: LOOP
			FETCH curEstatus INTO codigoEstatus, vEstatus;
			IF done THEN
				SET done = FALSE;
				CLOSE curEstatus;
				LEAVE estatus_loop;
			END IF;
			INSERT INTO info_movimiento(tipo_movimiento_nk, grupo, nombre_movimiento, estatus, codigo_estatus, naturaleza, version_actual_flag, ultima_actualizacion) VALUES (idTipoVenta, 'Venta', IF(codigoEstatus = '3', CONCAT("Cancelación ", vTipoVenta), vTipoVenta), vEstatus, codigoEstatus, IF(codigoEstatus = '3', -1, 1), 'Actual', CURDATE());
		END LOOP estatus_loop;
	END LOOP tipoventa_loop;
	CLOSE curTipoVenta;

	DROP TABLE IF EXISTS tmp_tipoventa_bi;
	DROP TABLE IF EXISTS tmp_estatus_bi;

	IF (SELECT COUNT(*) FROM info_movimiento WHERE info_movimiento_key = -1) = 0 THEN
		INSERT INTO info_movimiento(info_movimiento_key, tipo_movimiento_nk, grupo, nombre_movimiento, estatus, codigo_estatus, naturaleza) 
		VALUES(-1, -1, 'Desconocido', 'Desconocido', 'Desconocido', '', 0);
    END IF;

    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'info_movimiento', (SELECT COUNT(*) FROM info_movimiento));
END 
$$