DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_cliente`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_cliente`(IN flag bit(1), IN idEmpresa integer, IN baseDatosProd varchar(50), IN baseDatosBI varchar(50))
/*  
Fecha: JUNIO 2017
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos de la empresa
	Si flag = 1, Crea la tabla sino existe y la llena con los datos de la empresa
*/
BEGIN
	DECLARE fechaTiempoETL DATETIME;
    SET fechaTiempoETL = NOW();

	IF flag = 0 THEN 
		DROP TABLE IF EXISTS cliente;	
	END IF;

	CREATE TABLE IF NOT EXISTS cliente (
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

	SET @query = CONCAT("INSERT INTO ",baseDatosBI,".cliente(cliente_nk, nombre_cliente, estado_civil, regimen, 
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
        WHERE es_cliente = 1 and empresa = ", idEmpresa,";");
    PREPARE myQue FROM @query;
    EXECUTE myQue;

   IF (SELECT COUNT(*) FROM cliente WHERE cliente_key = -1) = 0 THEN 
		INSERT INTO cliente(cliente_key, cliente_nk, nombre_cliente, estado_civil, regimen, sexo) 
		VALUES(-1, -1, 'Desconocido', 'Desconocido', 'Desconocido', 'Desconocido');
	END IF;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'cliente', (SELECT COUNT(*) FROM cliente));
END
$$