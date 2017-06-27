DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_hechos_venta`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_hechos_venta`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_agente_venta;

	CREATE TABLE IF NOT EXISTS tmp_agente_venta (
		id INT NOT NULL AUTO_INCREMENT,
		empresa_id BIGINT(20) NOT NULL,
		venta_id BIGINT(20) NOT NULL,
		agente_asociado_id BIGINT(20) NOT NULL,
		es_agente_primario TINYINT(1) NOT NULL,
		porcentaje_participacion numeric(14,4) NOT NULL,
		PRIMARY KEY(id))
	ENGINE = MyISAM;

	CALL proc_consulta_registro_historico_etl(idEmpresa, 'fact_venta', @ultimaAct);

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_agente_venta (empresa_id, venta_id, agente_asociado_id, es_agente_primario, porcentaje_participacion)
		SELECT v.empresa, v.id as venta_id, v.agente_asociado_id, 1 AS es_agente_primario, 
			IFNULL(v.porcentaje_participacion, 0) AS porcentaje_participacion
		FROM ", baseDatosProd, ".venta as v
		WHERE v.empresa = ", idEmpresa, " AND (v.created_at > '", @ultimaAct, "' OR v.updated_at > '", @ultimaAct, "') AND v.created_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_agente_venta (empresa_id, venta_id, agente_asociado_id, es_agente_primario, porcentaje_participacion)
		SELECT av.empresa, av.venta_id, av.asociado_id, 0 AS es_agente_primario, 
			IFNULL(av.porcentaje_participacion, 0) AS porcentaje_participacion
		FROM ", baseDatosProd, ".agente_venta as av
		INNER JOIN ", baseDatosProd, ".venta AS v ON (av.venta_id = v.id)
		WHERE av.empresa = ", idEmpresa, " AND (av.created_at > '", @ultimaAct, "' OR av.updated_at > '", @ultimaAct, "') AND v.created_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	DROP TABLE IF EXISTS tmp_hechos_concentrado;

	CREATE TABLE IF NOT EXISTS tmp_hechos_concentrado (
		id INT NOT NULL AUTO_INCREMENT,
		venta_id BIGINT(20) NOT NULL,
		agente_id BIGINT(20) NOT NULL,
		cliente_id BIGINT(20) NOT NULL,
		empresa_id BIGINT(20) NOT NULL,
		tipo_venta_id BIGINT(20) NOT NULL,
		estatus_venta VARCHAR(1) NOT NULL,
		estatus_pago VARCHAR(11) NOT NULL,
		tipo_pago TINYINT(4) NOT NULL,
		moneda_id BIGINT(20) NOT NULL,
		plaza_id BIGINT(20) NOT NULL,
		producto_id BIGINT(20) NOT NULL,
		codigo_postal VARCHAR(6) NOT NULL,
		fecha_venta_id INT NOT NULL,
		es_agente_primario TINYINT(1) NOT NULL,
		porcentaje_participacion DECIMAL(16,4) NOT NULL,
		precio DECIMAL(16,4) NOT NULL,
		cantidad DECIMAL(16,4) NOT NULL,
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual', 
		ultima_actualizacion DATE NOT NULL DEFAULT '1901-01-01', 
		PRIMARY KEY(id))
	ENGINE = MyISAM;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_hechos_concentrado (venta_id, agente_id, cliente_id,  empresa_id, 
		tipo_venta_id, estatus_venta, estatus_pago, tipo_pago, moneda_id, plaza_id, producto_id, codigo_postal, fecha_venta_id,
		es_agente_primario, porcentaje_participacion, precio, cantidad, version_actual_flag, ultima_actualizacion) 
		SELECT v.id AS venta_id,
			IF(av.agente_asociado_id IS NULL OR av.agente_asociado_id = 0, -1, av.agente_asociado_id) AS agente_id, 
			IFNULL(v.cliente_asociado_id, -1) AS cliente_id, 
			IFNULL(v.empresa, -1) AS empresa_id, 
			IF(tv.id IS NULL, -1, tv.id) AS tipo_venta_id, 
            IF(v.estatus IS NULL OR v.estatus = '', '', v.estatus) AS estatus_venta, 
            CASE v.saldo 
				WHEN 0 THEN 'Pagada' 
				ELSE IF(v.saldo IS NULL,'Desconocido', 'Pendiente') 
			END AS estatus_pago, 
			IFNULL(v.tipo_pago, -1) as tipo_pago, 
			IFNULL(v.moneda_id, -1) as moneda_id, 
			IFNULL(pl.id, -1) AS plaza_id, 
			IFNULL(dv.producto_id, -1) AS producto_id, 
			IF(da.codigo_postal IS NULL OR da.codigo_postal = '', '00000', da.codigo_postal) AS codigo_postal,
			IF(v.fecha_cancelacion IS NULL OR v.fecha_cancelacion = '', '1901-01-01', v.fecha_cancelacion) + 0 AS fecha_venta_id, 
			IFNULL(av.es_agente_primario, -1) AS es_agente_primario,
			ROUND(IF(av.porcentaje_participacion IS NULL OR av.porcentaje_participacion = 0, 100, av.porcentaje_participacion), 4) AS porcentaje_participacion,
			ROUND(IFNULL(dv.precio_venta, 0), 4) AS precio,
			ROUND(IFNULL(dv.cantidad, 0),4) * -1 AS cantidad, 
			'Actual' AS version_actual_flag,
            CURDATE() 
		FROM ", baseDatosProd,".venta AS v
			INNER JOIN ", baseDatosProd,".detalle_venta AS dv ON (dv.venta_id = v.id)
			INNER JOIN ", baseDatosBI,".tmp_agente_venta AS av ON (av.venta_id = dv.venta_id)
			INNER JOIN ", baseDatosProd,".tipo_venta AS tv ON (v.tipoventa_id = tv.id)
			LEFT JOIN ", baseDatosProd,".plaza AS pl ON (pl.empresa = dv.empresa and pl.numero = v.plaza)
			LEFT JOIN ", baseDatosProd,".direccion_asociado AS da ON (v.direccion_asociado_id = da.id)
		WHERE v.empresa = ", idEmpresa," and tv.es_venta = 1 AND v.estatus = '3' AND v.updated_at > '", @ultimaAct, "' AND v.created_at <= '", @ultimaAct, "' AND v.updated_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	UPDATE fact_venta
	SET version_actual_flag = 'No Actual'
	WHERE venta_nk IN 
		(
			SELECT DISTINCT venta_id
			FROM tmp_hechos_concentrado
		) AND version_actual_flag = 'Actual';

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_hechos_concentrado (venta_id, agente_id, cliente_id,  empresa_id, 
		tipo_venta_id, estatus_venta, estatus_pago, tipo_pago, moneda_id, plaza_id, producto_id, codigo_postal, fecha_venta_id,
		es_agente_primario, porcentaje_participacion, precio, cantidad, version_actual_flag, ultima_actualizacion) 
		SELECT v.id AS venta_id,
			IF(av.agente_asociado_id IS NULL OR av.agente_asociado_id = 0, -1, av.agente_asociado_id) AS agente_id, 
			IFNULL(v.cliente_asociado_id, -1) AS cliente_id, 
			IFNULL(v.empresa, -1) AS empresa_id, 
			IF(tv.id IS NULL, -1, tv.id) AS tipo_movimiento_id, 
			CASE v.estatus
                WHEN '3' THEN '0'
                ELSE IF(v.estatus IS NULL OR v.estatus = '', '', v.estatus)
            END AS estatus_venta, 
            CASE v.saldo 
				WHEN 0 THEN 'Pagada' 
				ELSE IF(v.saldo IS NULL,'DESCONOCIDO', 'Pendiente') 
			END AS estatus_pago, 
			IFNULL(v.tipo_pago, -1) as tipo_pago, 
			IFNULL(v.moneda_id, -1) as moneda_id, 
			IFNULL(pl.id, -1) AS plaza_id, 
			IFNULL(dv.producto_id, -1) AS producto_id, 
			IF(da.codigo_postal IS NULL OR da.codigo_postal = '', '00000', da.codigo_postal) AS codigo_postal,
			IF(v.fecha IS NULL OR v.fecha = '', '1901-01-01', v.fecha) + 0 AS fecha_venta_id, 
			IFNULL(av.es_agente_primario, -1) AS es_agente_primario,
			ROUND(IFNULL(av.porcentaje_participacion, 0), 4) AS porcentaje_participacion,
			ROUND(IFNULL(dv.precio_venta, 0), 4) AS precio,
			ROUND(IFNULL(dv.cantidad, 0),4) AS cantidad, 
			CASE v.estatus
                WHEN '3' THEN 'No Actual'
                ELSE 'Actual'
            END AS version_actual_flag,
            CURDATE() 
		FROM ", baseDatosProd,".venta AS v
			INNER JOIN ", baseDatosProd,".detalle_venta AS dv ON (dv.venta_id = v.id)
			INNER JOIN ", baseDatosBI,".tmp_agente_venta AS av ON (av.venta_id = dv.venta_id)
			INNER JOIN ", baseDatosProd,".tipo_venta AS tv ON (v.tipoventa_id = tv.id)
			LEFT JOIN ", baseDatosProd,".plaza AS pl ON (pl.empresa = dv.empresa AND pl.numero = v.plaza)
			LEFT JOIN ", baseDatosProd,".direccion_asociado AS da ON (v.direccion_asociado_id = da.id)
		WHERE v.empresa = ", idEmpresa," AND tv.es_venta = 1 AND v.estatus IN ('0', '3') AND v.created_at > '", @ultimaAct, "' AND v.created_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_hechos_concentrado (venta_id, agente_id, cliente_id,  empresa_id, 
		tipo_venta_id, estatus_venta, estatus_pago, tipo_pago, moneda_id, plaza_id, producto_id, codigo_postal, fecha_venta_id,
		es_agente_primario, porcentaje_participacion, precio, cantidad, version_actual_flag, ultima_actualizacion) 
		SELECT v.id AS venta_id,
			IF(av.agente_asociado_id IS NULL OR av.agente_asociado_id = 0, -1, av.agente_asociado_id) AS agente_id, 
			IFNULL(v.cliente_asociado_id, -1) AS cliente_id, 
			IFNULL(v.empresa, -1) AS empresa_id, 
			IF(tv.id IS NULL, -1, tv.id) AS tipo_venta_id, 
            IF(v.estatus IS NULL OR v.estatus = '', '', v.estatus) AS estatus_venta, 
            CASE v.saldo 
				WHEN 0 THEN 'Pagada' 
				ELSE IF(v.saldo IS NULL,'Desconocido', 'Pendiente') 
			END AS estatus_pago, 
			IFNULL(v.tipo_pago, -1) as tipo_pago, 
			IFNULL(v.moneda_id, -1) as moneda_id, 
			IFNULL(pl.id, -1) AS plaza_id, 
			IFNULL(dv.producto_id, -1) AS producto_id, 
			IF(da.codigo_postal IS NULL OR da.codigo_postal = '', '00000', da.codigo_postal) AS codigo_postal,
			IF(v.fecha_cancelacion IS NULL OR v.fecha_cancelacion = '', '1901-01-01', v.fecha_cancelacion) + 0 AS fecha_venta_id, 
			IFNULL(av.es_agente_primario, -1) AS es_agente_primario,
			ROUND(IF(av.porcentaje_participacion IS NULL OR av.porcentaje_participacion = 0, 100, av.porcentaje_participacion), 4) AS porcentaje_participacion,
			ROUND(IFNULL(dv.precio_venta, 0), 4) AS precio,
			ROUND(IFNULL(dv.cantidad, 0),4) * -1 AS cantidad, 
			'Actual' AS version_actual_flag,
            CURDATE() 
		FROM ", baseDatosProd,".venta AS v
			INNER JOIN ", baseDatosProd,".detalle_venta AS dv ON (dv.venta_id = v.id)
			INNER JOIN ", baseDatosBI,".tmp_agente_venta AS av ON (av.venta_id = dv.venta_id)
			INNER JOIN ", baseDatosProd,".tipo_venta AS tv ON (v.tipoventa_id = tv.id)
			LEFT JOIN ", baseDatosProd,".plaza AS pl ON (pl.empresa = dv.empresa and pl.numero = v.plaza)
			LEFT JOIN ", baseDatosProd,".direccion_asociado AS da ON (v.direccion_asociado_id = da.id)
		WHERE v.empresa = ", idEmpresa," AND tv.es_venta = 1 AND v.estatus = '3' AND v.created_at > '", @ultimaAct, "' AND v.created_at <= '", fechaTiempoETL, "';");
	PREPARE myQue FROM @query;
	EXECUTE myQue;

	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_venta ON ", baseDatosBI,".tmp_hechos_concentrado(venta_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_cliente ON ", baseDatosBI,".tmp_hechos_concentrado(cliente_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_producto ON ", baseDatosBI,".tmp_hechos_concentrado(producto_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_agente ON ", baseDatosBI,".tmp_hechos_concentrado(agente_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_empresa ON ", baseDatosBI,".tmp_hechos_concentrado(empresa_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_plaza ON ", baseDatosBI,".tmp_hechos_concentrado(plaza_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_moneda ON ", baseDatosBI,".tmp_hechos_concentrado(moneda_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_fecha ON ", baseDatosBI,".tmp_hechos_concentrado(fecha_venta_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;	
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_tipo_venta ON ", baseDatosBI,".tmp_hechos_concentrado(tipo_venta_id);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_codigo_postal ON ", baseDatosBI,".tmp_hechos_concentrado(codigo_postal);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_estatus_venta ON ", baseDatosBI,".tmp_hechos_concentrado(estatus_venta);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_estatus_pago ON ", baseDatosBI,".tmp_hechos_concentrado(estatus_pago);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;
	SET @qIndx = CONCAT("CREATE INDEX ix_tmp_hechos_concentrado_tipo_pago ON ", baseDatosBI,".tmp_hechos_concentrado(tipo_pago);");
	PREPARE myQue FROM @qIndx;
	EXECUTE myQue;

	INSERT INTO fact_venta(venta_nk, cliente_key, producto_key, agente_key, empresa_key,
	moneda_key, plaza_key, territorio_key, info_pago_key, info_movimiento_key, tiempo_venta_key, es_agente_primario,
	porcentaje_participacion, importe, cantidad, version_actual_flag, ultima_actualizacion) 
	SELECT th.venta_id,
		IF(c.cliente_key IS NULL, -1, c.cliente_key) AS cliente_key,
		IF(p.producto_key IS NULL, -1, p.producto_key) AS producto_key, 
		IF(a.agente_key IS NULL, -1, a.agente_key) AS agente_key,
		IF(e.empresa_key IS NULL, -1, e.empresa_key) AS empresa_key,
		IF(m.moneda_key IS NULL, -1, m.moneda_key) AS moneda_key,
		IF(pl.plaza_key IS NULL, -1, pl.plaza_key) AS plaza_key,
		IF(t.territorio_key IS NULL, -1, t.territorio_key) AS territorio_key,
		IF(ip.info_pago_key IS NULL, -1, ip.info_pago_key) AS info_pago_key,
		IF(im.info_movimiento_key IS NULL, -1, im.info_movimiento_key) AS info_movimiento_key, 
		IF(tmp.fecha_key IS NULL, -1, tmp.fecha_key) AS fecha_key,
		CASE th.es_agente_primario
			WHEN 1 THEN 'Si'
			WHEN 0 THEN 'No'
			ELSE 'Desconocido'
		END AS es_agente_primario,
		IF(th.porcentaje_participacion IS NULL OR th.porcentaje_participacion = 0, 100, th.porcentaje_participacion) AS porcentaje_participacion,
		ROUND(th.precio*th.cantidad*(IF(th.porcentaje_participacion = 0, 100, porcentaje_participacion)/100),4) AS importe,
		IF(th.cantidad IS NULL OR th.cantidad = 0, 100, th.cantidad) AS cantidad,
		IF(th.version_actual_flag IS NULL OR th.version_actual_flag = 0, 100, th.version_actual_flag) AS version_actual_flag,
		IF(th.ultima_actualizacion IS NULL OR th.ultima_actualizacion = 0, 100, th.ultima_actualizacion) AS ultima_actualizacion
	FROM tmp_hechos_concentrado AS th 
	LEFT JOIN agente AS a ON (th.agente_id = a.agente_nk) 
	LEFT JOIN cliente AS c ON (th.cliente_id = c.cliente_nk) 
	INNER JOIN empresa AS e ON (th.empresa_id = e.empresa_nk)
	INNER JOIN info_movimiento AS im ON (th.tipo_venta_id = im.tipo_movimiento_nk AND th.estatus_venta = im.codigo_estatus) 
	INNER JOIN info_pago AS ip ON (th.tipo_pago = ip.codigo_tipo_pago AND th.estatus_pago = ip.estatus_pago) 
	LEFT JOIN moneda AS m ON (th.moneda_id = m.moneda_nk) 
	INNER JOIN plaza AS pl ON (th.plaza_id = pl.plaza_nk)  
	LEFT JOIN producto AS p ON (th.producto_id = p.producto_nk)
	LEFT JOIN territorio AS t ON (th.codigo_postal = t.codigo_postal) 
	LEFT JOIN tiempo AS tmp ON (th.fecha_venta_id = tmp.fecha_key);

    DROP TABLE IF EXISTS tmp_hechos_concentrado;
    DROP TABLE IF EXISTS tmp_agente_venta;
        
    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'fact_venta', (SELECT COUNT(*) FROM fact_venta));
END
$$