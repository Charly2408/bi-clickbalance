DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_actualiza_dimension_cliente`;

DELIMITER $$

CREATE PROCEDURE `proc_actualiza_dimension_cliente`(IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
*/
BEGIN
	DROP TABLE IF EXISTS tmp_cliente;

	CREATE TABLE IF NOT EXISTS tmp_cliente (
		cliente_key INT NOT NULL AUTO_INCREMENT,
		cliente_nk BIGINT(20) NOT NULL,
		nombre_cliente VARCHAR(245) NOT NULL DEFAULT 'Desconocido',
		estado_civil VARCHAR(12) NOT NULL DEFAULT 'Desconocido',
		regimen VARCHAR(15) NOT NULL DEFAULT 'Desconocido',
		sexo VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT 1901-01-01,
		PRIMARY KEY (cliente_key),
		UNIQUE INDEX ix_cliente_key (cliente_key ASC),
		INDEX ix_cliente_nk (cliente_nk ASC))
	ENGINE = MyISAM;

	CALL proc_consulta_registro_historico_etl(idEmpresa, 'cliente', @ultimaAct);

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".tmp_cliente(cliente_nk, nombre_cliente, estado_civil, regimen, 
		sexo, version_actual_flag, ultima_actualizacion) 
		select id, 
		CASE regimen 
            WHEN 'PF' THEN IF((nombre IS NULL OR nombre = '') AND (apellido_paterno IS NULL OR apellido_paterno = '') AND (apellido_materno IS NULL OR apellido_materno = ''), 'DESCONOCIDO', CONCAT(nombre, ' ', apellido_paterno, ' ', apellido_materno)) 
            WHEN 'PM' THEN IF(razon_social IS NULL OR razon_social = '', 'Desconocido', razon_social)
            ELSE 'Desconocido' 
        END AS nombre_o_razon_social,
        CASE estado_civil
			WHEN 'S' THEN 'Soltero' 
			WHEN 'C' THEN 'Casado' 
			WHEN 'D' THEN 'Divorciado' 
			WHEN 'U' THEN 'Union Libre' 
			ELSE 'DESCONOCIDO' 
		END AS estado_civil,
        CASE regimen 
            WHEN 'PF' THEN 'PERSONA FISICA'
            WHEN 'PM' THEN 'PERSONA MORAL'
            ELSE 'Desconocido' 
        END AS regimen_fiscal,
        CASE sexo 
        	WHEN 'M' THEN 'Masculino'
        	WHEN 'F' THEN 'Femenino'
        	ELSE 'Desconocido'
        END AS sexo, 
        'Actual', 
        CURDATE() 
        FROM ", baseDatosProd, ".asociado
        WHERE es_cliente = 1 and empresa = ", idEmpresa," AND (created_at > '", @ultimaAct, "' OR updated_at > '", @ultimaAct, "');");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

    -- Manejo de cambios Tipo 1
	UPDATE cliente AS c  
		INNER JOIN tmp_cliente AS tc ON (tc.cliente_nk = c.cliente_nk)
	SET c.sexo = tc.sexo,
		c.ultima_actualizacion = IF(c.version_actual_flag = 'Actual', tc.ultima_actualizacion, c.ultima_actualizacion)
	WHERE c.sexo <> tc.sexo;

	-- Manejo de cambios Tipo 2
	DROP TABLE IF EXISTS tmp_cliente_a_historico;

	CREATE TABLE IF NOT EXISTS tmp_cliente_a_historico
	SELECT c.cliente_key, c.cliente_nk
    FROM tmp_cliente AS tc 
    	INNER JOIN cliente AS c ON (tc.cliente_nk = c.cliente_nk)
    WHERE c.version_actual_flag = 'Actual' AND (c.nombre_cliente <> tc.nombre_cliente OR c.estado_civil <> tc.estado_civil OR c.regimen <> tc.regimen);

	INSERT INTO cliente(cliente_nk, nombre_cliente, estado_civil, regimen, sexo, version_actual_flag, ultima_actualizacion)
	SELECT tc.cliente_nk, tc.nombre_cliente, tc.estado_civil, tc.regimen, tc.sexo, tc.version_actual_flag, tc.ultima_actualizacion
    FROM tmp_cliente AS tc 
    	INNER JOIN cliente AS c ON (tc.cliente_nk = c.cliente_nk)
    WHERE c.version_actual_flag = 'Actual' AND (c.nombre_cliente <> tc.nombre_cliente OR c.estado_civil <> tc.estado_civil OR c.regimen <> tc.regimen);

    UPDATE cliente AS c
    	INNER JOIN tmp_cliente_a_historico AS tch ON (c.cliente_key = tch.cliente_key)
    SET c.version_actual_flag = 'No Actual';

    DROP TABLE IF EXISTS tmp_cliente_version_actual;

    CREATE TABLE IF NOT EXISTS tmp_cliente_version_actual
    SELECT c.cliente_key AS cliente_key_actual, tch.cliente_key AS cliente_key_historica
    FROM cliente AS c
    	INNER JOIN tmp_cliente_a_historico AS tch ON (c.cliente_nk = tch.cliente_nk)
    WHERE c.version_actual_flag = 'Actual';

    UPDATE fact_venta AS fv 
    	INNER JOIN tmp_cliente_version_actual AS tcva ON (fv.cliente_key = tcva.cliente_key_historica)
    SET fv.cliente_key = tcva.cliente_key_historica;

    -- Manejando la inserción de registros con llaves naturales que no existen en la BD de análisis
    INSERT INTO cliente(cliente_nk, nombre_cliente, estado_civil, regimen, sexo, version_actual_flag, ultima_actualizacion)
    SELECT tc.cliente_nk, tc.nombre_cliente, tc.estado_civil, tc.regimen, tc.sexo, tc.version_actual_flag, tc.ultima_actualizacion
    FROM tmp_cliente as tc 
    	LEFT JOIN cliente as c ON (tc.cliente_nk = c.cliente_nk)
    WHERE c.cliente_nk IS NULL;

    DROP TABLE IF EXISTS tmp_cliente;
    DROP TABLE IF EXISTS tmp_cliente_a_historico;
    DROP TABLE IF EXISTS tmp_cliente_version_actual;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'cliente', (SELECT COUNT(*) FROM cliente));
END
$$