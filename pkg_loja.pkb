-- ---------------------------------------------------------------------------------------------
--- SIBD-2425 - 2024/2025 - Etapa 4 - Grupo 25
-- Diogo Roque (fc61857) - TP11, Omeir Haroon (fc61810) - TP11, Miguel Ferreira (fc61879) - TP14
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_loja IS

-- --------------------------------------------------------
-- ----- Códigos de exceção -----
-- - -20000, 'Erro não esperado.'
-- - -20001, 'Cliente tem de ter pelo menos 16 anos de idade.'
-- - -20002, 'O ano de lançamento tem de ser anterior ao ano atual.'
-- - -20003, 'A data da fatura tem de ser posterior à data de colocação do equipamento na Loja.'
-- - -20004, 'Nenhum equipamento encontrado com o EAN e número de exemplar dado.'
-- - -20005, 'Não existe equipamento registado com o EAN e exemplar na fatura.'
-- - -20006, 'Não existe equipamento registado com o EAN e EXEMPLAR dado.'
-- - -20007, 'Não existe ficha de equipamento registado com o EAN dado.'
-- - -20008, 'Violação da condição UNIQUE ou chave primária: '
-- - -20009, 'Violação de uma condição CHECK'
-- - -20010, 'Violação de integridade - chave pai não encontrado'
-- - -20011, 'Violação de integridade -  chave filho encontrada'
-- - -20012, 'Não é possível inserir NULL numa coluna'
-- - -20013, 'Nenhuma fatura encontrada com o número de sequência dado.
-- - -20014, 'Ficha de equipamento não existente para dado EAN.' -- no_data_found
-- -  ^^^^ por algum motivo este erro(-20014) não é apanhado e apenas é capturado na função de lidar com exceções como other
-- ---------------------------------------------------------
-- NOTA: Compilar duas vezes para gerar a sequencia!!
-- ---------------------------------------------------------
-- ----- Funções e procedimentos -----
PROCEDURE lidar_excecoes(
    codigo NUMBER
    )IS
        restricao VARCHAR2(32767);
        mensagem VARCHAR2(32767);
        BEGIN CASE codigo
                WHEN -1 THEN
                    restricao := REGEXP_SUBSTR(SQLERRM, 'constraint \\(([^\\.]+)\\.([^\\)]+)\\)', 1, 1, NULL, 2); -- obter nome da restrição
                    mensagem := 'Violação da condição UNIQUE ou chave primária: ' || restricao || '.';
                    RAISE_APPLICATION_ERROR(-20008, mensagem);
                WHEN -2290 THEN
                    restricao := REGEXP_SUBSTR(SQLERRM, 'constraint \\(([^\\.]+)\\.([^\\)]+)\\)', 1, 1, NULL, 2);
                    mensagem := 'Violação de uma condição CHECK' || restricao || '.';
                    RAISE_APPLICATION_ERROR(-20009, mensagem);
                WHEN -2291 THEN
                    restricao := REGEXP_SUBSTR(SQLERRM, 'constraint \\(([^\\.]+)\\.([^\\)]+)\\)', 1, 1, NULL, 2);
                    mensagem := 'Violação de integridade - chave pai não encontrado';
                    RAISE_APPLICATION_ERROR(-20010, mensagem);
                WHEN -2292 THEN
                    restricao := REGEXP_SUBSTR(SQLERRM, 'constraint \\(([^\\.]+)\\.([^\\)]+)\\)', 1, 1, NULL, 2);
                    mensagem := 'Violação de integridade -  chave filho não encontrada';
                    RAISE_APPLICATION_ERROR(-20011, mensagem);
                WHEN -1400 THEN
                    restricao := REGEXP_SUBSTR(SQLERRM, 'constraint \\(([^\\.]+)\\.([^\\)]+)\\)', 1, 1, NULL, 2);
                    mensagem := 'Não é possível inserir NULL numa coluna';
                    RAISE_APPLICATION_ERROR(-20012, mensagem);
                WHEN -01403 THEN -- no_data_found
                    mensagem := 'Ficha de equipamento não existente para dado EAN.';
                    RAISE_APPLICATION_ERROR(-20014, mensagem);
                ELSE
                    mensagem := 'Erro não esperado: ' || SQLERRM;
                    RAISE_APPLICATION_ERROR(-20000, mensagem);
            END CASE;
                
    END lidar_excecoes;

PROCEDURE regista_cliente(
    nif_in IN cliente.nif%TYPE,
    nome_in IN cliente.nome%TYPE,
    telemovel_in IN cliente.telemovel%TYPE,
    genero_in IN cliente.genero%TYPE,
    nascimento_in IN cliente.nascimento%TYPE,
    localidade_in IN cliente.localidade%TYPE
    ) IS
    BEGIN
        DECLARE 
            current_year NUMBER;
        BEGIN --guardar o valor do ano atual, para comparar com a idade
            current_year := EXTRACT(YEAR FROM SYSDATE);
            IF (current_year - nascimento_in) >= 16 THEN
                INSERT INTO cliente (nif, nome, telemovel, genero, nascimento, localidade)
                VALUES (nif_in, nome_in, telemovel_in, genero_in, nascimento_in, localidade_in);
            ELSE
                RAISE_APPLICATION_ERROR(-20001, 'Cliente tem de ter pelo menos 16 anos de idade.  (RIA 9, adaptada)');
            END IF;
        END;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN -- cliente já registado
            UPDATE cliente
            SET nome = nome_in,
                telemovel = telemovel_in,
                genero = genero_in,
                nascimento = nascimento_in,
                localidade = localidade_in
            WHERE nif = nif_in;
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END regista_cliente;

-- --------------------------------------------------------
PROCEDURE regista_ficha(
        ean_in IN ficha.ean%TYPE, 
        marca_in IN ficha.marca%TYPE, 
        modelo_in IN ficha.modelo%TYPE, 
        tipo_in IN ficha.tipo%TYPE, 
        ano_in IN ficha.ano%TYPE, 
        preco_in IN equipamento.preco%TYPE
    ) IS
    BEGIN

        BEGIN
            -- Tenta atualizar a ficha existente
            UPDATE ficha
            SET marca = marca_in,
                modelo = modelo_in,
                tipo = tipo_in,
                ano = ano_in,
                preco = preco_in
            WHERE ean = ean_in;

            IF ano_in >= EXTRACT(YEAR FROM SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20002, 'O ano de lançamento tem de ser anterior ao ano atual. (RIA 10)');
            END IF;
            -- Verifica se alguma linha foi atualizada
            IF SQL%ROWCOUNT = 0 THEN
                INSERT INTO ficha (ean, marca, modelo, tipo, ano, preco)
                VALUES (ean_in, marca_in, modelo_in, tipo_in, ano_in, preco_in);
            END IF;
            
            UPDATE equipamento
            SET preco = preco_in
            WHERE ficha = ean_in;

        EXCEPTION
            WHEN OTHERS THEN
                lidar_excecoes(SQLCODE);
        END;

    END regista_ficha;

-- --------------------------------------------------------
FUNCTION regista_equipamento(
    ean_in IN ficha.ean%TYPE,
    estado_in IN equipamento.estado%TYPE,
    preco_in IN equipamento.preco%TYPE,
    data_in IN equipamento.data%TYPE := SYSDATE
    ) RETURN NUMBER IS
        n_exemplar NUMBER;
    BEGIN
        BEGIN
            SELECT exemplar
            INTO n_exemplar
            FROM ficha fi, equipamento e
            WHERE fi.ean = ean_in AND e.ficha = ean_in
            FOR UPDATE;

            -- Obter o próximo número de exemplar
            SELECT COALESCE(MAX(exemplar) + 1, 1)
            INTO n_exemplar
            FROM equipamento
            WHERE ficha = ean_in;
        END;
        INSERT INTO equipamento (ficha, exemplar, estado, preco, data)
        VALUES (ean_in, n_exemplar, estado_in, preco_in, data_in);

        RETURN n_exemplar;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO equipamento (ficha, exemplar, estado, preco, data)
            VALUES (ean_in, 1, estado_in, preco_in, data_in);
            RETURN 1;
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END regista_equipamento;

-- --------------------------------------------------------
FUNCTION regista_compra(
        cliente_in IN cliente.nif%TYPE,
        ean_in IN ficha.ean%TYPE,
        exemplar_in IN equipamento.exemplar%TYPE,
        fatura_in IN fatura.numero%TYPE := NULL
    ) RETURN NUMBER IS
        n_fatura NUMBER;
        data_colocacao DATE;
        data_fatura DATE;
    BEGIN
        -- Obter data de colocação do equipamento e data da fatura
        SELECT data
        INTO data_colocacao
        FROM equipamento
        WHERE ficha = ean_in AND exemplar = exemplar_in;
        -- Data da fatura
        IF fatura_in IS NOT NULL THEN
            SELECT data
            INTO data_fatura
            FROM fatura
            WHERE numero = fatura_in;

            IF data_fatura <= data_colocacao THEN
                RAISE_APPLICATION_ERROR(-20003, 'A data da fatura tem de ser posterior à data de colocação do equipamento na Loja.');
            ELSE
                n_fatura := fatura_in;
            END IF;
        ELSE -- Se não for fornecido um número de fatura, gerar um novo
            INSERT INTO fatura (numero, data, cliente)
            VALUES (fatura_seq.NEXTVAL, SYSDATE, cliente_in);

            SELECT fatura_seq.CURRVAL INTO n_fatura FROM dual;
        END IF;

        UPDATE equipamento
        SET fatura = n_fatura
        WHERE ficha = ean_in AND exemplar = exemplar_in;

        RETURN n_fatura;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nenhum equipamento encontrado com o EAN e número de exemplar dado.');
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END regista_compra;

-- --------------------------------------------------------
FUNCTION remove_compra(
    fatura_in IN fatura.numero%TYPE,
    ean_in IN equipamento.ficha%TYPE := NULL,
    exemplar_in IN equipamento.exemplar%TYPE := NULL
    ) RETURN NUMBER IS
        remaining_lines NUMBER;
    BEGIN
    
        IF ean_in IS NOT NULL AND exemplar_in IS NOT NULL THEN
            DELETE FROM equipamento
            WHERE ficha = ean_in AND exemplar = exemplar_in AND fatura = fatura_in;

            UPDATE equipamento
            SET fatura = NULL
            WHERE ficha = ean_in AND exemplar = exemplar_in;
            
            IF SQL%ROWCOUNT = 0 THEN
                RAISE_APPLICATION_ERROR(-20013, 'Nenhuma fatura encontrada com o número de sequência dado.');
            END IF;
        ELSE
            FOR rec IN (SELECT ficha, exemplar FROM equipamento WHERE fatura = fatura_in) LOOP
                DECLARE
                    dump_var NUMBER;
                BEGIN
                    dump_var := remove_compra(fatura_in, rec.ficha, rec.exemplar);
                END;
            END LOOP;
            RETURN 0;
        END IF;
        
        SELECT COUNT(*)
        INTO remaining_lines
        FROM equipamento
        WHERE fatura = fatura_in;
    RETURN remaining_lines;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Não existe equipamento registado com o EAN e exemplar na fatura.');
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END remove_compra;

-- --------------------------------------------------------
    PROCEDURE remove_equipamento(
        ean_in IN equipamento.ficha%TYPE,
        exemplar_in IN equipamento.exemplar%TYPE
    ) IS
        fatura_in fatura.numero%TYPE;
    BEGIN
        SELECT fatura
        INTO fatura_in
        FROM equipamento
        WHERE ficha = ean_in AND exemplar = exemplar_in;

        DECLARE
            variavel_dump NUMBER;
        BEGIN
            variavel_dump := remove_compra(fatura_in, ean_in, exemplar_in);
        END;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Não existe equipamento registado com o EAN e EXEMPLAR dado.');
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END remove_equipamento;

-- --------------------------------------------------------
-- remove a ficha e todos os equipamentos associados
PROCEDURE remove_ficha(
        ean_in IN ficha.ean%TYPE
    ) IS
        contagem NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO contagem
        FROM ficha
        WHERE ean = ean_in;
        
        IF contagem = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Não existe ficha de equipamento registado com o EAN dado.');
        END IF;

        DELETE FROM equipamento
        WHERE ficha = ean_in;

        DELETE FROM ficha
        WHERE ean = ean_in;
    EXCEPTION
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END remove_ficha;

-- --------------------------------------------------------
-- Remove o cliente com NIF, bem como todas as suas compras de equipamentos usados
    PROCEDURE remove_cliente(
        nif_in IN cliente.nif%TYPE
    ) IS
        contagem NUMBER;
    BEGIN
        -- verificar se o cliente existe
        SELECT COUNT(*)
        INTO contagem
        FROM cliente
        WHERE nif = nif_in;

        IF contagem = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Não existe cliente registado com o NIF dado.');
        ELSE
            FOR f IN (SELECT numero FROM fatura WHERE cliente = nif_in) LOOP
                DECLARE
                    dump_var NUMBER;
                BEGIN
                    dump_var := remove_compra(f.numero);
                END;

            END LOOP;
        END IF;

        DELETE FROM fatura
        WHERE cliente = nif_in;

        DELETE FROM cliente
        WHERE nif = nif_in;

    EXCEPTION
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END remove_cliente;

    FUNCTION lista_compras(  
        cliente_in IN cliente.nif%TYPE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT f.numero, f.data, e.ficha, e.exemplar, fi.marca, fi.modelo, e.preco
            FROM fatura f, equipamento e, ficha fi
            WHERE f.numero = e.fatura AND f.cliente = cliente_in AND fi.ean = e.ficha
            ORDER BY f.data DESC, e.preco DESC;
        
        RETURN v_cursor;
    
    EXCEPTION
        WHEN OTHERS THEN
            lidar_excecoes(SQLCODE);
    END lista_compras;
END pkg_loja;
/

CREATE SEQUENCE fatura_seq 
START WITH 10000
INCREMENT BY 1;