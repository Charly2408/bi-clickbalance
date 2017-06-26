DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_territorio`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_territorio`(IN flag bit(1), IN baseDatosProd varchar(50), IN baseDatosBI varchar(50), IN fechaTiempoETL DATETIME)
/* 
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS territorio;
	END IF;

	CREATE TABLE IF NOT EXISTS territorio (
		territorio_key BIGINT(20) AUTO_INCREMENT NOT NULL,
		codigo_postal_nk BIGINT(20) NOT NULL,
		codigo_postal VARCHAR(6) NOT NULL DEFAULT '00000',
		pais VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
		estado VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
		localidad VARCHAR(100) NOT NULL DEFAULT 'Desconocida',
		version_actual_flag VARCHAR(10) NOT NULL DEFAULT 'Actual',
		ultima_actualizacion DATE NOT NULL DEFAULT '1901-01-01',
		PRIMARY KEY (territorio_key),
		UNIQUE INDEX ix_territorio_key (territorio_key ASC),
		INDEX ix_codigo_postal_nk (codigo_postal_nk ASC),
		INDEX ix_codigo_postal (codigo_postal ASC))
	ENGINE = MyISAM;

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".territorio(codigo_postal_nk, codigo_postal, pais, estado, localidad, version_actual_flag, ultima_actualizacion) 
		SELECT cp.id as cod_postal_cb_id, 
			IF(cp.codigo_postal IS NULL OR cp.codigo_postal = '', '00000', cp.codigo_postal) as codigo_postal, 
			IF(p.descripcion IS NULL OR p.descripcion = '', 'Desconocido', p.descripcion) as pais, 
			IF(e.nombre IS NULL OR e.nombre = '', 'Desconocido', e.nombre) as estado, 
			IF(l.descripcion IS NULL OR l.descripcion = '', 'Desconocida', l.descripcion) as localidad, 
			'Actual', CURDATE() 
		FROM ",baseDatosProd,".sat_codigo_postal AS cp 
		INNER JOIN ",baseDatosProd,".sat_estado AS e ON (cp.estado = e.estado_sat)
		INNER JOIN ",baseDatosProd,".sat_pais as p ON (p.abreviatura_sat = e.pais_sat)
		LEFT JOIN ",baseDatosProd,".sat_localidad AS l ON (cp.localidad = l.localidad AND cp.estado = l.estado)");
	PREPARE myQue FROM @query;
    EXECUTE myQue;

    DROP TABLE IF EXISTS tmp_codigo_postal;

    SET @query = CONCAT("CREATE TABLE ",baseDatosBI,".tmp_codigo_postal 
		SELECT id as cp_repetido_id 
		FROM ",baseDatosProd,".sat_codigo_postal 
		WHERE codigo_postal IN 
			(
				SELECT codigo_postal 
				FROM ",baseDatosProd,".sat_codigo_postal 
				GROUP BY codigo_postal HAVING count(*) > 1
			) AND localidad = '';");
	PREPARE myQue FROM @query;
    EXECUTE myQue;

    DELETE FROM territorio 
    WHERE codigo_postal_nk IN 
    	(
    		SELECT cp_repetido_id 
    		FROM tmp_codigo_postal
    	);

   	DELETE FROM territorio
   	WHERE codigo_postal = '00000';

    DROP TABLE IF EXISTS tmp_codigo_postal;

    IF (SELECT COUNT(*) FROM territorio WHERE territorio_key = -1) = 0 THEN 
	    INSERT INTO territorio (territorio_key, codigo_postal_nk, codigo_postal, pais, estado, localidad) 
		VALUES(-1, -1, '00000', 'Desconocido', 'Desconocido', 'Desconocida');
	END IF;

    CALL proc_crea_registro_historico_etl(1, 0, fechaTiempoETL, 'territorio', (SELECT COUNT(*) FROM territorio));
END
$$