CREATE TABLE myschema.tb_tx_outbox (
    id numeric(49) NOT NULL,
    nm_topico_saida varchar(100) NULL,
    dc_body bytea NULL,
    tp_midia varchar(100) NULL,
    nm_topico_ok varchar(100) NULL,
    nm_topico_rnna varchar(100) NULL,
    fl_cdc bool NOT NULL,
    dt_operacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT pk_tb_outbox PRIMARY KEY (id)
);