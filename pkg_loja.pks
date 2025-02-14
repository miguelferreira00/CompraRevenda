-- ----------------------------------------------------------------------------------------------
--- SIBD-2425 - 2024/2025 - Etapa 4 - Grupo 25
-- Diogo Roque (fc61857) - TP11, Omeir Haroon (fc61810) - TP11, Miguel Ferreira (fc61879) - TP14
-- ----------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_loja AS

PROCEDURE lidar_excecoes(
    codigo NUMBER
);

PROCEDURE regista_cliente(
    nif_in IN cliente.nif%TYPE,
    nome_in IN cliente.nome%TYPE,
    telemovel_in IN cliente.telemovel%TYPE,
    genero_in IN cliente.genero%TYPE,
    nascimento_in IN cliente.nascimento%TYPE,
    localidade_in IN cliente.localidade%TYPE
);

PROCEDURE regista_ficha(
    ean_in IN ficha.ean%TYPE, 
    marca_in IN ficha.marca%TYPE, 
    modelo_in IN ficha.modelo%TYPE, 
    tipo_in IN ficha.tipo%TYPE, 
    ano_in IN ficha.ano%TYPE, 
    preco_in IN equipamento.preco%TYPE
);

FUNCTION regista_equipamento(
    ean_in IN ficha.ean%TYPE,
    estado_in IN equipamento.estado%TYPE,
    preco_in IN equipamento.preco%TYPE,
    data_in IN equipamento.data%TYPE := SYSDATE
) RETURN NUMBER;

FUNCTION regista_compra(
    cliente_in IN cliente.nif%TYPE,
    ean_in IN ficha.ean%TYPE,
    exemplar_in IN equipamento.exemplar%TYPE,
    fatura_in IN fatura.numero%TYPE := NULL
) RETURN NUMBER; -- gera novo numero de fatura automaticamente por uma sequencia oracle
-- necessario criar a sequencia no inicio do script de demonstração

FUNCTION remove_compra(
    fatura_in IN fatura.numero%TYPE,
    ean_in IN equipamento.ficha%TYPE := NULL,
    exemplar_in IN equipamento.exemplar%TYPE := NULL
) RETURN NUMBER;-- devolve o número de linhas restantes na fatura

PROCEDURE remove_equipamento(
    ean_in IN equipamento.ficha%TYPE,
    exemplar_in IN equipamento.exemplar%TYPE
);


PROCEDURE remove_ficha(
    ean_in IN ficha.ean%TYPE
);
--
PROCEDURE remove_cliente(
    nif_in IN cliente.nif%TYPE
);


FUNCTION lista_compras(
    cliente_in IN cliente.nif%TYPE
) RETURN SYS_REFCURSOR;
--

END pkg_loja;
/