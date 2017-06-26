DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_info_movimiento`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_info_movimiento`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	DECLARE idTipoVenta BIGINT(20);
	DECLARE vTipoVenta VARCHAR(50);
	DECLARE codigoEstatus VARCHAR(1);
	DECLARE vEstatus VARCHAR(11);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE curTipoVenta CURSOR FOR SELECT id, nombre FROM tmp_tipoventa_bi;
    DECLARE curEstatus CURSOR FOR SELECT codigo_estatus, estatus FROM tmp_estatus_bi;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	DROP TABLE IF EXISTS tmp_estatus_bi;

	CREATE TABLE tmp_estatus_bi (
		codigo_estatus VARCHAR(1) NOT NULL,
		estatus VARCHAR(11) NOT NULL);
	
	INSERT INTO tmp_estatus_bi (codigo_estatus, estatus)
	VALUES 
	('0', 'Terminado'),
	('3', 'Cancelado'),
	('', 'Desconocido');

	CALL proc_consulta_registro_historico_etl(idEmpresa, 'info_movimiento', @ultimaAct);

	DROP TABLE IF EXISTS tmp_tipoventa_bi;

	SET @query = CONCAT("CREATE TABLE tmp_tipoventa_bi 
		SELECT id, 
		IF(descripcion IS NULL OR descripcion = '', 'Desconocido', descripcion) as nombre 
    	FROM ", baseDatosProd, ".tipo_venta 
    	WHERE empresa = ", idEmpresa, " AND es_venta = 1 AND created_at > '", @ultimaAct, "' AND created_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

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
			INSERT INTO info_movimiento(tipo_movimiento_nk, grupo, nombre_movimiento, estatus, codigo_estatus, naturaleza, version_actual_flag, ultima_actualizacion) 
			VALUES (idTipoVenta, 'Venta', IF(codigoEstatus = '3', CONCAT("Cancelación ", vTipoVenta), vTipoVenta), vEstatus, codigoEstatus, IF(codigoEstatus = '3', -1, 1), 'Actual', CURDATE());
		END LOOP estatus_loop;
	END LOOP tipoventa_loop;
	CLOSE curTipoVenta;

	DROP TABLE IF EXISTS tmp_tipoventa_bi;
	DROP TABLE IF EXISTS tmp_estatus_bi;

    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'info_movimiento', (SELECT COUNT(*) FROM info_movimiento));
END 
$$