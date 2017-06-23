DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_producto`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_producto`(IN flag bit(1), IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS producto;
	END IF;

	CREATE TABLE IF NOT EXISTS producto (
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

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".producto(producto_nk, nombre_grupo, codigo_producto, nombre_producto, 
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
		WHERE p.empresa = ", idEmpresa, " AND p.created_at <= '", fechaTiempoETL, "';");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    DROP TABLE IF EXISTS productos_nombre_repetido;

	CREATE TABLE IF NOT EXISTS productos_nombre_repetido 
		SELECT producto_key FROM producto 
		WHERE nombre_producto IN 
			(
				SELECT nombre_producto 
				FROM producto 
				GROUP BY producto HAVING count(*) > 1
			);

	CREATE INDEX ix_producto_key ON productos_nombre_repetido(producto_key);

	UPDATE producto AS p 
    	INNER JOIN  productos_nombre_repetido AS pnr ON (p.producto_key = pnr.producto_key) 
    SET p.producto = CONVERT(CONCAT(p.producto, '-' ,p.codigo) USING utf8);

    DROP TABLE IF EXISTS productos_nombre_repetido;

    IF (SELECT COUNT(*) FROM producto WHERE producto_key = -1) = 0 THEN 
	    INSERT INTO producto(producto_key, producto_nk, nombre_grupo, codigo_producto, nombre_producto, marca, tipo) 
	VALUES(-1, -1, 'Desconocido', 'Desconocido', 'Desconocido', 'Desconocida', 'Desconocido');
    END IF;

    CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'producto', (SELECT COUNT(*) FROM producto));
END
$$