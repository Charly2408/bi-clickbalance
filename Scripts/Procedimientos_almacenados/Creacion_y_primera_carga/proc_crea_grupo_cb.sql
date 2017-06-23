DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_grupo_cb`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_grupo_cb`(IN flag bit(1), IN nombreGrupo varchar(50))
/*
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea nuevamente e inserta el registro.
	Si flag = 1, Crea la tabla sino existe e inserta el registro.
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS grupo_cb;
	END IF;

	CREATE TABLE IF NOT EXISTS grupo_cb (
		grupo_id INT NOT NULL AUTO_INCREMENT,
		nombre_grupo VARCHAR(50) NOT NULL DEFAULT 'Desconocido',
		PRIMARY KEY (grupo_id),
		UNIQUE INDEX ix_grupo_id (grupo_id ASC))
	ENGINE = InnoDB;

	INSERT INTO grupo_cb (nombre_grupo)
	VALUES (nombreGrupo);
END
$$