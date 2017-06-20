-- MySQL Script generated by MySQL Workbench
-- Tue Jun 20 09:54:27 2017
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema datamart
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema datamart
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `datamart` DEFAULT CHARACTER SET utf8 ;
USE `datamart` ;

-- -----------------------------------------------------
-- Table `datamart`.`producto`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`producto` (
  `producto_key` INT NOT NULL AUTO_INCREMENT,
  `producto_nk` BIGINT(20) NOT NULL,
  `nombre_grupo` VARCHAR(30) NOT NULL DEFAULT 'DESCONOCIDO',
  `nombre_producto` VARCHAR(300) NOT NULL DEFAULT 'Desconocido',
  `marca` VARCHAR(40) NOT NULL DEFAULT 'Desconocida',
  `tipo` VARCHAR(11) NOT NULL DEFAULT 'DESCONOCIDO',
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`producto_key`),
  UNIQUE INDEX `ix_producto_key` (`producto_key` ASC),
  INDEX `ix_producto_nk` (`producto_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`cliente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`cliente` (
  `cliente_key` INT NOT NULL AUTO_INCREMENT,
  `cliente_nk` BIGINT(20) NOT NULL,
  `nombre_cliente` VARCHAR(245) NOT NULL DEFAULT 'Desconocido',
  `estado_civil` VARCHAR(12) NOT NULL DEFAULT 'Desconocido',
  `regimen` VARCHAR(15) NOT NULL DEFAULT 'Desconocido',
  `sexo` VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`cliente_key`),
  UNIQUE INDEX `ix_cliente_key` (`cliente_key` ASC),
  INDEX `ix_cliente_nk` (`cliente_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`agente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`agente` (
  `agente_key` INT NOT NULL AUTO_INCREMENT,
  `agente_nk` BIGINT(20) NOT NULL,
  `nombre_agente` VARCHAR(245) NOT NULL DEFAULT 'Desconocido',
  `tipo_agente` VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
  `estatus_agente` VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
  `sexo` VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`agente_key`),
  UNIQUE INDEX `ix_agente_key` (`agente_key` ASC),
  INDEX `ix_agente_nk` (`agente_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`empresa`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`empresa` (
  `empresa_key` INT NOT NULL AUTO_INCREMENT,
  `empresa_nk` BIGINT(20) NOT NULL,
  `razon_social` VARCHAR(245) NOT NULL DEFAULT 'Desconocida',
  `nombre_comercial` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `regimen` VARCHAR(15) NOT NULL DEFAULT 'Desconocido',
  `sector` VARCHAR(16) NOT NULL DEFAULT 'Desconocido',
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`empresa_key`),
  UNIQUE INDEX `ix_empresa_key` (`empresa_key` ASC),
  INDEX `ix_empresa_nk` (`empresa_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`moneda`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`moneda` (
  `moneda_key` INT NOT NULL AUTO_INCREMENT,
  `moneda_nk` INT NOT NULL,
  `nombre_moneda` VARCHAR(50) NOT NULL DEFAULT 'Desconocido',
  `abreviatura` VARCHAR(11) NOT NULL DEFAULT 'Desconocida',
  `cambio_a_peso_mexicano` DECIMAL(16,4) NOT NULL,
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`moneda_key`),
  UNIQUE INDEX `ix_moneda_key` (`moneda_key` ASC),
  INDEX `ix_moneda_nk` (`moneda_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`tiempo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`tiempo` (
  `fecha_key` INT NOT NULL,
  `fecha` DATE NOT NULL,
  `anio` TINYINT(1) NOT NULL,
  `mes` VARCHAR(10) NOT NULL,
  `dia_del_mes` TINYINT(1) NOT NULL,
  `dia_nombre` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`fecha_key`),
  UNIQUE INDEX `ix_fecha_key` (`fecha_key` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`info_pago`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`info_pago` (
  `info_pago_key` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tipo_pago` VARCHAR(7) NOT NULL DEFAULT 'Ninguno',
  `estatus_pago` VARCHAR(7) NOT NULL,
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`info_pago_key`),
  UNIQUE INDEX `ix_info_pago_key` (`info_pago_key` ASC))
ENGINE = MyISAM
DEFAULT CHARACTER SET = big5;


-- -----------------------------------------------------
-- Table `datamart`.`plaza`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`plaza` (
  `plaza_key` INT NOT NULL AUTO_INCREMENT,
  `plaza_nk` BIGINT(20) NOT NULL,
  `nombre_plaza` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `numero_plaza` INT NOT NULL,
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`plaza_key`),
  UNIQUE INDEX `ix_plaza_key` (`plaza_key` ASC),
  INDEX `ix_plaza_nk` (`plaza_nk` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`territorio`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`territorio` (
  `territorio_key` BIGINT(20) NOT NULL,
  `codigo_postal_nk` BIGINT(20) NOT NULL,
  `codigo_postal` VARCHAR(6) NOT NULL DEFAULT '00000',
  `pais` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `estado` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `localidad` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`territorio_key`),
  UNIQUE INDEX `ix_territorio_key` (`territorio_key` ASC),
  INDEX `ix_codigo_postal_nk` (`codigo_postal_nk` ASC),
  INDEX `ix_codigo_postal` (`codigo_postal` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`info_movimiento`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`info_movimiento` (
  `info_movimiento_key` INT NOT NULL AUTO_INCREMENT,
  `tipo_movimiento_nk` BIGINT(20) NOT NULL,
  `grupo` VARCHAR(20) NOT NULL DEFAULT 'Desconocido',
  `nombre_movimiento` VARCHAR(65) NOT NULL DEFAULT 'Desconocido',
  `estatus` VARCHAR(11) NOT NULL DEFAULT 'Desconocido',
  `codigo_estatus` VARCHAR(1) NOT NULL,
  `naturaleza` TINYINT(1) NOT NULL,
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  PRIMARY KEY (`info_movimiento_key`),
  UNIQUE INDEX `ix_tipo_movimiento_key` (`info_movimiento_key` ASC),
  INDEX `ix_tipo_movimiento_nk` (`tipo_movimiento_nk` ASC),
  INDEX `ix_codigo_estatus` (`codigo_estatus` ASC))
ENGINE = MyISAM;


-- -----------------------------------------------------
-- Table `datamart`.`fact_ventas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `datamart`.`fact_ventas` (
  `fact_venta_key` INT NOT NULL AUTO_INCREMENT,
  `cliente_key` INT NOT NULL,
  `producto_key` INT NOT NULL,
  `agente_key` INT NOT NULL,
  `empresa_key` INT NOT NULL,
  `moneda_key` INT NOT NULL,
  `plaza_key` INT NOT NULL,
  `territorio_plaza_key` BIGINT(20) NOT NULL,
  `info_pago_key` INT NOT NULL,
  `info_movimiento_key` INT NOT NULL,
  `tiempo_venta_key` INT NOT NULL,
  `tiempo_pago_key` INT NOT NULL,
  `porcentaje_participacion` DECIMAL(16,4) NOT NULL,
  `precio` DECIMAL(16,4) NOT NULL,
  `cantidad` DECIMAL(16,4) NOT NULL,
  `costo` DECIMAL(16,4) NOT NULL,
  `saldo` DECIMAL(16,4) NOT NULL,
  `version_actual_flag` VARCHAR(10) NOT NULL DEFAULT 'Actual',
  `ultima_actualizacion` DATE NOT NULL DEFAULT 1901-01-01,
  INDEX `ix_fact_ventas_cliente_key` (`cliente_key` ASC),
  INDEX `ix_fact_ventas_producto_key` (`producto_key` ASC),
  INDEX `ix_fact_ventas_agente_key` (`agente_key` ASC),
  INDEX `ix_fact_ventas_empresa_key` (`empresa_key` ASC),
  INDEX `ix_fact_ventas_moneda_key` (`moneda_key` ASC),
  INDEX `ix_fact_ventas_tiempo_venta_key` (`tiempo_venta_key` ASC),
  INDEX `ix_fact_ventas_tiempo_pago_key` (`tiempo_pago_key` ASC),
  INDEX `ix_fact_ventas_info_pago_key` (`info_pago_key` ASC),
  INDEX `ix_fact_ventas_plaza_key` (`plaza_key` ASC),
  INDEX `ix_fact_ventas_territorio_plaza_key` (`territorio_plaza_key` ASC),
  INDEX `ix_info_movimiento_key` (`info_movimiento_key` ASC),
  PRIMARY KEY (`fact_venta_key`),
  UNIQUE INDEX `ix_fact_venta_key` (`fact_venta_key` ASC),
  CONSTRAINT `fk_fact_ventas_cliente`
    FOREIGN KEY (`cliente_key`)
    REFERENCES `datamart`.`cliente` (`cliente_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_agente`
    FOREIGN KEY (`agente_key`)
    REFERENCES `datamart`.`agente` (`agente_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_producto`
    FOREIGN KEY (`producto_key`)
    REFERENCES `datamart`.`producto` (`producto_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_empresa`
    FOREIGN KEY (`empresa_key`)
    REFERENCES `datamart`.`empresa` (`empresa_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_moneda`
    FOREIGN KEY (`moneda_key`)
    REFERENCES `datamart`.`moneda` (`moneda_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_tiempo_venta`
    FOREIGN KEY (`tiempo_venta_key`)
    REFERENCES `datamart`.`tiempo` (`fecha_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_tiempo_pago`
    FOREIGN KEY (`tiempo_pago_key`)
    REFERENCES `datamart`.`tiempo` (`fecha_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_info_pago`
    FOREIGN KEY (`info_pago_key`)
    REFERENCES `datamart`.`info_pago` (`info_pago_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_plaza`
    FOREIGN KEY (`plaza_key`)
    REFERENCES `datamart`.`plaza` (`plaza_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_territorio`
    FOREIGN KEY (`territorio_plaza_key`)
    REFERENCES `datamart`.`territorio` (`territorio_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_ventas_info_movimiento1`
    FOREIGN KEY (`info_movimiento_key`)
    REFERENCES `datamart`.`info_movimiento` (`info_movimiento_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
