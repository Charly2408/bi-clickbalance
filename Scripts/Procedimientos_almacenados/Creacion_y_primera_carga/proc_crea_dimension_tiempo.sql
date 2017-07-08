DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_tiempo`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_tiempo`(IN flag bit(1), IN fechaInicial DATE, IN fechaFinal DATE, IN fechaTiempoETL DATETIME)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos
	Si flag = 1, Crea la tabla sino existe y la llena con los datos
*/
BEGIN
	DECLARE varDate DATE DEFAULT fechaInicial;
    DECLARE varMes tinyint;

	IF flag = 0 THEN
		DROP TABLE IF EXISTS tiempo;
	END IF;

	CREATE TABLE IF NOT EXISTS tiempo (
		fecha_key INT NOT NULL,
		fecha DATE NOT NULL,
		anio SMALLINT(4) NOT NULL,
		mes VARCHAR(10) NOT NULL,
		dia_del_mes TINYINT(2) NOT NULL,
		dia_nombre VARCHAR(10) NOT NULL,
		PRIMARY KEY (fecha_key),
		UNIQUE INDEX ix_fecha_key (fecha_key ASC))
	ENGINE = MyISAM;

    WHILE varDate < fechaFinal DO
        SET varMes := MONTH(varDate);
        INSERT INTO tiempo(fecha_key, fecha, anio, mes, dia_del_mes, dia_nombre)
            VALUES(varDate + 0, varDate, YEAR(varDate), DATE_FORMAT(varDate, '%M'), DATE_FORMAT(varDate, '%d'), DATE_FORMAT(varDate, '%W'));
        SET varDate := varDate + INTERVAL 1 DAY;
    END WHILE;

    IF (SELECT COUNT(*) FROM tiempo WHERE fecha_key = 19010101) = 0 THEN 
	    INSERT INTO tiempo(fecha_key, fecha, anio, mes, dia_del_mes, dia_nombre) 
		VALUES(19010101, '1901-01-01', -1, 'N/D', -1, 'N/D');
	END IF;

	CALL proc_crea_registro_historico_etl(1, 0, fechaTiempoETL, 'tiempo', (SELECT COUNT(*) FROM tiempo));
END
$$