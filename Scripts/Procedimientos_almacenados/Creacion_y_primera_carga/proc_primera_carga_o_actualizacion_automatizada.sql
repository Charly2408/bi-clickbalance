DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_primera_carga_o_actualizacion_automatizada`;

DELIMITER $$

CREATE PROCEDURE `proc_primera_carga_o_actualizacion_automatizada`(IN flag BIT(1), IN grupoId INT, IN baseDatosProd VARCHAR(50), IN baseDatosBI VARCHAR(50), IN fechaInicial DATE, IN fechaFinal DATE)
/*
Autor: Carlos Audelo
	Si flag = 0, Realiza proceso de primera carga
	Si flag = 1, Realiza proceso de actualizacion de informacion
*/
BEGIN
	DECLARE fechaTiempoETL DATETIME DEFAULT NOW();
	DECLARE flagBorradoTablas BIT(1) DEFAULT 0;
	DECLARE empresaId INT;
	DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE curEmpresa CURSOR FOR SELECT empresa_cb_id FROM tmp_empresa_cb;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DROP TABLE IF EXISTS tmp_empresa_cb;

    SET @query = CONCAT("CREATE TABLE IF NOT EXISTS tmp_empresa_cb 
    	SELECT empresa_cb_id 
    	FROM empresa_cb 
    	WHERE grupo_id = ", grupoId, ";");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	OPEN curEmpresa;
	IF flag = 0 THEN
		empresa_loop: LOOP
			FETCH curEmpresa INTO empresaId;
			IF done THEN
				LEAVE empresa_loop;
			END IF;
			IF flagBorradoTablas = 0 THEN
				CALL proc_crea_registro_historico_etl(0, 0, '0000-00-00 00:00:00', '', 0);
				CALL proc_crea_dimension_info_pago(flagBorradoTablas, baseDatosProd, baseDatosBI, fechaTiempoETL);
				CALL proc_crea_dimension_moneda(flagBorradoTablas, baseDatosProd, baseDatosBI, fechaTiempoETL);
				CALL proc_crea_dimension_territorio(flagBorradoTablas, baseDatosProd, baseDatosBI, fechaTiempoETL);
				CALL proc_crea_dimension_tiempo(flagBorradoTablas, fechaInicial, fechaFinal, fechaTiempoETL);
			END IF;
			CALL proc_crea_dimension_agente(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_crea_dimension_cliente(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);			
			CALL proc_crea_dimension_empresa(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_crea_dimension_info_movimiento(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_crea_dimension_plaza(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_crea_dimension_producto(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_crea_hechos_venta(flagBorradoTablas, empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			SET flagBorradoTablas = 1;
		END LOOP empresa_loop;
	ELSE
		SET flagBorradoTablas = 1;
		empresa_loop: LOOP
			FETCH curEmpresa INTO empresaId;
			IF done THEN
				LEAVE empresa_loop;
			END IF;
			CALL proc_crea_dimension_tiempo(flagBorradoTablas, fechaInicial, fechaFinal, fechaTiempoETL);
			CALL proc_actualiza_dimension_agente(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_actualiza_dimension_cliente(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);			
			CALL proc_actualiza_dimension_empresa(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_actualiza_dimension_info_movimiento(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_actualiza_dimension_plaza(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_actualiza_dimension_producto(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
			CALL proc_actualiza_hechos_venta(empresaId, baseDatosProd, baseDatosBI, fechaTiempoETL);
		END LOOP empresa_loop;
	END IF;
	CLOSE curEmpresa;

	DROP TABLE IF EXISTS tmp_empresa_cb;
END
$$