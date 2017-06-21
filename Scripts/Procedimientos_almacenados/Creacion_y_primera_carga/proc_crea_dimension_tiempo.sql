DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_dimension_tiempo`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_dimension_tiempo`(IN flag bit(1), IN baseDatosBI varchar(50), fechaInicial DATE, fechaFinal DATE)
/*  
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea y la llena con los datos
	Si flag = 1, Crea la tabla sino existe y la llena con los datos
*/
BEGIN
	DECLARE varDate DATE DEFAULT fechaInicial;
    DECLARE varMes tinyint;
    DECLARE fechaTiempoETL DATETIME;

    SET fechaTiempoETL = NOW();

	IF flag = 0 THEN 

		SET @qDelete = CONCAT("DROP TABLE IF EXISTS ", baseDatosBI,".tiempo;");
        PREPARE myQue FROM @qDelete;
        EXECUTE myQue;
	
	END IF;

	CREATE TABLE IF NOT EXISTS tiempo (
		fecha_key INT NOT NULL,
		fecha DATE NOT NULL,
		anio TINYINT(1) NOT NULL,
		mes VARCHAR(10) NOT NULL,
		dia_del_mes TINYINT(1) NOT NULL,
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

    IF (SELECT COUNT(*) FROM tiempo WHERE tiempo_key = 19010101) = 0 THEN 
	    INSERT INTO tiempo(fecha_key, fecha, anio, mes, dia_del_mes, dia_nombre) 
		VALUES(19010101, '1901-01-01', -1, 'N/D', -1, 'N/D');
	IF END;

	CALL proc_crea_registro_historico_etl(1, idEmpresa, fechaTiempoETL, 'tiempo', (SELECT COUNT(*) FROM tiempo));
END
$$