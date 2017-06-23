DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_crea_empresa_cb`;

DELIMITER $$

CREATE PROCEDURE `proc_crea_empresa_cb`(IN flag bit(1), IN empresaCBId BIGINT(20), IN nombreEmpresa varchar(50), IN grupoId INT)
/*
Autor: Carlos Audelo
	Si flag = 0, Borra la tabla, la crea nuevamente e inserta el registro.
	Si flag = 1, Crea la tabla sino existe e inserta el registro.
*/
BEGIN
	IF flag = 0 THEN 
		DROP TABLE IF EXISTS empresa_cb;
	END IF;

	CREATE TABLE IF NOT EXISTS empresa_cb (
		empresa_id INT NOT NULL AUTO_INCREMENT,
		empresa_cb_id BIGINT(20) NOT NULL,
		nombre_empresa VARCHAR(50) NOT NULL DEFAULT 'Desconocido',
		grupo_id INT NOT NULL,
		PRIMARY KEY (empresa_id),
		UNIQUE INDEX ix_empresa_id (empresa_id ASC),
		INDEX ix_empresa_cb_id (empresa_cb_id ASC),
		CONSTRAINT fk_empresa_grupo
		    FOREIGN KEY (grupo_id)
		    REFERENCES grupo_cb (grupo_id)
		    ON DELETE NO ACTION
		    ON UPDATE NO ACTION)
	ENGINE = InnoDB;

	INSERT INTO empresa_cb (empresa_cb_id, nombre_empresa, grupo_id)
	VALUES (empresaCBId, nombreEmpresa, grupoId);
END
$$