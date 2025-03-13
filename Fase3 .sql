-- ---------------------------------------------------------------------------- 
DROP TABLE equipamento; 
DROP TABLE fatura; 
DROP TABLE ficha; 
DROP TABLE cliente; 
-- ALTER SESSION SET NLS_DATE_FORMAT = 'DD.MM.YYYY';
-- ---------------------------------------------------------------------------- 
CREATE TABLE cliente ( 
	-- Adaptação, contendo atributos de Pessoa e, adicionalmente, 
	-- o ano de nascimento do Empregado e a localidade da Morada. 
	nif         NUMBER (9), 
	nome       VARCHAR (80) CONSTRAINT nn_cliente_nome       NOT NULL, 
	telemovel   NUMBER (9)  CONSTRAINT nn_cliente_telemovel  NOT NULL, 
	genero        CHAR (1),  -- Pode não ser preenchido. 
	nascimento  NUMBER (4)  CONSTRAINT nn_cliente_nascimento NOT NULL, 
													 -- Só o ano de nascimento. 
	localidade VARCHAR (80) CONSTRAINT nn_cliente_localidade NOT NULL, 
-- 
	CONSTRAINT pk_cliente 
		PRIMARY KEY (nif), 
-- 
	CONSTRAINT un_cliente_telemovel  -- RIA 24, adaptada a esta tabela. 
		UNIQUE (telemovel), 
-- 
	CONSTRAINT ck_cliente_nif  -- RIA 21, adaptada a esta tabela. 
		CHECK (nif BETWEEN 100000000 AND 999999999), 
-- 
	CONSTRAINT ck_cliente_telemovel  -- RIA 23, adaptada a esta tabela. 
		CHECK (telemovel BETWEEN 100000000 AND 999999999), 
-- 
	CONSTRAINT ck_cliente_genero  -- RIA 22, adaptada a esta tabela. 
		CHECK (genero IN ('F', 'M')),  -- F(eminino), M(asculino), se preenchido. 
-- 
	CONSTRAINT ck_cliente_nascimento  -- Impede erros básicos. 
		CHECK (nascimento >= 1900) 
); 
-- ---------------------------------------------------------------------------- 
CREATE TABLE ficha (  -- Ficha de equipamento. 
	ean     NUMBER (13), 
	marca  VARCHAR (80)  CONSTRAINT nn_ficha_marca  NOT NULL, 
	modelo VARCHAR (80)  CONSTRAINT nn_ficha_modelo NOT NULL, 
	tipo   VARCHAR (80)  CONSTRAINT nn_ficha_tipo   NOT NULL, 
	ano     NUMBER (4)   CONSTRAINT nn_ficha_ano    NOT NULL,  -- De lançamento. 
	preco   NUMBER (7,2) CONSTRAINT nn_ficha_preco  NOT NULL,  -- De lançamento. 
-- 
	CONSTRAINT pk_ficha 
		PRIMARY KEY (ean), 
-- 
	CONSTRAINT ck_ficha_ean  -- RIA 29. 
		CHECK (ean BETWEEN 1000000000000 AND 9999999999999), 
-- 
	CONSTRAINT ck_ficha_ano  -- Impede erros básicos. 
		CHECK (ano >= 1900), 
-- 
	CONSTRAINT ck_ficha_preco  -- RIA 30. 
		CHECK (preco > 0.0) 
); 
-- ---------------------------------------------------------------------------- 
CREATE TABLE fatura ( 
	-- Simplificação, sem referência à Loja e ao Empregado. 
	numero    NUMBER (5), 
	data        DATE     CONSTRAINT nn_fatura_data      NOT NULL, 
	cliente              CONSTRAINT nn_fatura_cliente   NOT NULL, 
-- 
	CONSTRAINT pk_fatura 
		PRIMARY KEY (numero), 
-- 
	CONSTRAINT fk_fatura_cliente 
		FOREIGN KEY (cliente) 
		REFERENCES cliente (nif), 
-- 
	CONSTRAINT ck_fatura_numero  -- RIA 35, parcialmente. 
		 CHECK (numero >= 1), 
-- 
	CONSTRAINT ck_fatura_data  -- Não suporta RIA 12, mas impede erros 
		CHECK (data >= TO_DATE('01.01.1900', 'DD.MM.YYYY'))  -- básicos. 
); 
-- ---------------------------------------------------------------------------- 
CREATE TABLE equipamento ( 
	-- Simplificação, sem referência à Loja, pelo que um 
	-- Equipamento é uma entidade fraca de Ficha (de Equipamento). 
	ficha, 
	exemplar NUMBER (5), 
	estado     CHAR (3)   CONSTRAINT nn_equipamento_estado NOT NULL, 
	preco    NUMBER (7,2) CONSTRAINT nn_equipamento_preco  NOT NULL,  -- Na loja. 
	data       DATE       CONSTRAINT nn_equipamento_data   NOT NULL,  -- Na loja. 
	fatura,  -- Só é preenchida quando o equipamento for 
					 -- vendido a um cliente, no âmbito de uma fatura. 
-- 
	CONSTRAINT pk_equipamento 
		PRIMARY KEY (ficha, exemplar), 
-- 
	CONSTRAINT fk_equipamento_ficha 
		FOREIGN KEY (ficha) 
		REFERENCES ficha (ean) 
		ON DELETE CASCADE, 
-- 
	CONSTRAINT fk_equipamento_fatura 
		FOREIGN KEY (fatura) 
		REFERENCES fatura (numero), 
-- 
	CONSTRAINT ck_equipamento_exemplar  -- RIA 32, parcialmente. 
		CHECK (exemplar >= 1), 
-- 
	CONSTRAINT ck_equipamento_estado  -- RIA 33. 
		CHECK (estado IN ('BOM', 'MAU')), 
-- 
	CONSTRAINT ck_equipamento_preco  -- RIA 34. 
		CHECK (preco > 0.0), 
-- 
	CONSTRAINT ck_equipamento_data  -- Não suporta RIA 11, mas impede erros 
		CHECK (data >= TO_DATE('01.01.1900', 'DD.MM.YYYY'))  -- básicos. 
); 
-- ----------------------------------------------------------------------------
-- INSERTS AQUI

-- ------------------------------------------------------------------------------
-- QUERIES AQUI

