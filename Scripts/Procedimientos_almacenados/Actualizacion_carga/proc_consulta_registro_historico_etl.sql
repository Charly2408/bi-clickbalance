DELIMITER ;

DROP PROCEDURE IF EXISTS `proc_consulta_registro_historico_etl`;

DELIMITER $$

CREATE PROCEDURE `proc_consulta_registro_historico_etl`(IN idEmpresa BIGINT(20), IN nombreTabla varchar(50), OUT ultimaActualizacion DATETIME)
/*
Autor: Carlos Audelo
*/
BEGIN
	SELECT MAX(ultima_actualizacion) 
	FROM historico_etl 
	WHERE empresa_cb_id = idEmpresa AND nombre_dimension_o_hecho = nombreTabla INTO ultimaActualizacion;
END
$$