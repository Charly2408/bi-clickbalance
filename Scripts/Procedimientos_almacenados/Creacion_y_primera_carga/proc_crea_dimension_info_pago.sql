DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_info_pago`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_info_pago`(IN flag bit(1), IN baseDatosProd varchar(50), IN baseDatosBI varchar(50))
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	DECLARE fechaTiempoETL DATETIME;
	DECLARE tipoPagoCode TINYINT(4);
	DECLARE vTipoPago VARCHAR(11);
	DECLARE vEstatusPago VARCHAR(11);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE curTipoPago CURSOR FOR SELECT codigo_tipo_pago, tipo_pago FROM tmp_tipopago_bi;
    DECLARE curEstatusPago CURSOR FOR SELECT estatus_pago FROM tmp_estatuspago_bi;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET fechaTiempoETL = NOW();

	IF flag = 0 THEN 
		DROP TABLE IF EXISTS info_pago;
	END IF;

	DROP TABLE IF EXISTS tmp_tipopago_bi;
	
	CREATE TABLE tmp_tipopago_bi(
		codigo_tipo_pago TINYINT(4) NOT NULL,
		tipo_pago VARCHAR(11) NOT NULL DEFAULT 'Desconocido');
	
	INSERT INTO tmp_tipopago_bi (tipo_pago_code, tipo_pago)
	VALUES 
	(0, 'Contado'),
	(1, 'Crédito'),
	(-1, 'Desconocido');

	DROP TABLE IF EXISTS tmp_estatuspago_bi;
	
	CREATE TABLE tmp_estatuspago_bi(
		estatus_pago VARCHAR(11) NOT NULL DEFAULT 'Desconocido');
	
	INSERT INTO tmp_estatuspago_bi (estatus_pago)
	VALUES 
	('Pagada'),
	('Pendiente'),
	('Desconocido');

	CREATE TABLE IF NOT EXISTS info_pago (
		info_pago_key INT NOT NULL AUTO_INCREMENT,
		tipo_pago VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		codigo_tipo_pago TINYINT(4) NOT NULL,
		estatus_pago VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01,
		PRIMARY KEY (info_pago_key),
		UNIQUE INDEX ix_info_pago_key (info_pago_key ASC),
		INDEX ix_codigo_tipo_pago (codigo_tipo_pago ASC),
		INDEX ix_estatus_pago (estatus_pago ASC))
	ENGINE = MyISAM;

	OPEN curTipoPago;
	tipopago_loop: LOOP
		FETCH curTipoPago INTO tipoPagoCode, vTipoPago;
		IF done THEN
			LEAVE tipopago_loop;
		END IF;
		OPEN curEstatusPago;
		estatuspago_loop: LOOP
			FETCH curEstatusPago INTO vEstatusPago;
			IF done THEN
				SET done = FALSE;
				CLOSE curEstatusPago;
				LEAVE estatuspago_loop;
			END IF;
			INSERT INTO info_pago(tipo_pago, codigo_tipo_pago, estatus_pago, version_actual_flag, ultima_actualizacion) VALUES (tipoPagoCode, vTipoPago, vEstatusPago, 'Actual', CURDATE());
		END LOOP estatuspago_loop;
	END LOOP tipopago_loop;
	CLOSE curTipoPago;

	DROP TABLE IF EXISTS tmp_tipopago_bi;
	DROP TABLE IF EXISTS tmp_estatuspago_bi;

	IF (SELECT COUNT(*) FROM info_pago WHERE info_pago_key = -1) = 0 THEN 
		INSERT INTO info_pago(info_pago_key, tipo_pago, codigo_tipo_pago, estatus_pago) 
		VALUES(-1, 'Desconocido', -1, 'Desconocido');
	END IF;

	CALL proc_inserta_registro_historico_etl(0, fechaTiempoETL, 'info_pago', (SELECT COUNT(*) FROM info_pago));
END 
$$