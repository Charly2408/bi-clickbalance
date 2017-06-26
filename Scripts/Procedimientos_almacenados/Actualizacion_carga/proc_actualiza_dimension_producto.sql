DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_producto`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_producto`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_producto;

	CREATE TABLE IF NOT EXISTS tmp_producto (
		producto_key INT NOT NULL AUTO_INCREMENT,
		producto_nk BIGINT(20) NOT NULL,
		nombre_grupo VARCHAR(30) NOT NULL DEFAULT 'Desconocido',
		codigo_producto VARCHAR(25) NOT NULL DEFAULT 'Desconocido', 
		nombre_producto VARCHAR(300) NOT NULL DEFAULT 'Desconocido',
		marca VARCHAR(40) NOT NULL DEFAULT 'Desconocida',
		tipo VARCHAR(11) NOT NULL DEFAULT 'DESCONOCIDO',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT '1901-01-01',,
		PRIMARY KEY (producto_key),
		UNIQUE INDEX ix_producto_key (producto_key ASC),
		INDEX ix_producto_nk (producto_nk ASC))
	ENGINE = MyISAM;

	CALL proc_consulta_registro_historico_etl(idEmpresa, 'producto', @ultimaAct);

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_producto(producto_nk, nombre_grupo, codigo_producto, nombre_producto, 
		marca, tipo, version_actual_flag, ultima_actualizacion) 
		SELECT 
		p.id as prod_id, 
		IF(g.nombre IS NULL OR g.nombre = '', 'Desconocido', g.nombre) AS group_name,
		IF(p.codigo IS NULL OR p.codigo = '', 'Desconocido', p.codigo) AS prod_code,  
		IF(p.nombre IS NULL OR p.nombre = '', 'Desconocido', p.nombre) AS prod_name, 
		IF(p.marca IS NULL OR p.marca = '', 'Desconocida', p.marca) AS prod_brand, 
		CASE p.tipo 
			WHEN 'P' THEN 'Producto' 
			WHEN 'S' THEN 'Servicio' 
			WHEN 'A' THEN 'Activo' 
			ELSE 'Desconocido' 
		END AS prod_type, 
		'Actual', 
		CURDATE() 
		FROM ",baseDatosProd,".producto AS p 
		LEFT JOIN ", baseDatosProd, ".grupo AS g ON (p.grupo_id = g.id)
		WHERE p.empresa = ", idEmpresa," AND (created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "') AND created_at <= '", fechaTiempoETL, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 1
	UPDATE producto AS p  
		INNER JOIN tmp_producto as tp ON (tp.producto_nk = p.producto_nk)
	SET p.tipo = tp.tipo,
		p.ultima_actualizacion = IF(p.version_actual_flag = 'Actual', tp.ultima_actualizacion, p.ultima_actualizacion)
	WHERE p.tipo <> tp.tipo;

    -- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_producto_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_producto_a_historico
	SELECT p.producto_key, p.producto_nk
    FROM tmp_producto AS tp 
    	INNER JOIN producto AS p ON (tp.producto_nk = p.producto_nk)
    WHERE p.version_actual_flag = 'Actual' AND (p.nombre_grupo <> tp.nombre_grupo OR p.codigo_producto <> tp.codigo_producto OR p.nombre_producto <> tp.nombre_producto OR p.marca <> tp.marca);

	INSERT INTO producto(producto_nk, nombre_grupo, codigo_producto, nombre_producto, marca, tipo, version_actual_flag, ultima_actualizacion)
	SELECT tp.producto_nk, tp.nombre_grupo, tp.codigo_producto, tp.nombre_producto, tp.marca, tp.tipo, tp.version_actual_flag, tp.ultima_actualizacion
    FROM tmp_producto AS tp 
    	INNER JOIN producto AS p ON (tp.producto_nk = p.producto_nk)
    WHERE p.version_actual_flag = 'Actual' AND (p.nombre_grupo <> tp.nombre_grupo OR p.codigo_producto <> tp.codigo_producto OR p.nombre_producto <> tp.nombre_producto OR p.marca <> tp.marca);

    UPDATE producto AS p
    	INNER JOIN tmp_producto_a_historico AS tph ON (p.producto_key = tph.producto_key)
    SET p.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_producto_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_producto_version_actual
    SELECT p.producto_key AS producto_key_actual, tph.producto_key AS producto_key_historica
    FROM producto AS p
    	INNER JOIN tmp_producto_a_historico AS tph ON (p.producto_nk = tph.producto_nk)
    WHERE p.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_producto_version_actual AS tpva ON (fv.producto_key = tpva.producto_key_historica)
    SET fv.producto_key = tpva.producto_key_actual;

    -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO producto(producto_nk, nombre_grupo, codigo_producto, nombre_producto, marca, tipo, version_actual_flag, ultima_actualizacion)
    SELECT tp.producto_nk, tp.nombre_grupo, tp.codigo_producto, tp.nombre_producto, tp.marca, tp.tipo, tp.version_actual_flag, tp.ultima_actualizacion
    FROM tmp_producto as tp 
    	LEFT JOIN producto as p ON (tp.producto_nk = p.producto_nk)
    WHERE p.producto_nk IS NULL;

    DROP TABLE IF EXISTS tmp_producto;
    DROP TABLE IF EXISTS tmp_producto_a_historico;
    DROP TABLE IF EXISTS tmp_producto_version_actual;

    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'producto', (SELECT COUNT(*) FROM producto));
END
$$