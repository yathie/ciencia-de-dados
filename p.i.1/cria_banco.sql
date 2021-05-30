--criando tabelas isoladas de origem

drop table tb_consulta_cand_2018_AP;
CREATE TABLE tb_consulta_cand_2018_AP(
	DS_CARGO VARCHAR(30), 
	SQ_CANDIDATO VARCHAR(12), 
	NR_CANDIDATO VARCHAR(8), 
	NM_CANDIDATO VARCHAR(50), 
	NM_URNA_CANDIDATO VARCHAR(50),
	DS_SITUACAO_CANDIDATURA  VARCHAR(20),
	DS_DETALHE_SITUACAO_CAND VARCHAR(50),
	TP_AGREMIACAO VARCHAR(20), 
	NR_PARTIDO VARCHAR(3), 
	SG_PARTIDO VARCHAR(50), 
	NM_PARTIDO VARCHAR(50), 
	SQ_COLIGACAO VARCHAR(15),
	NM_COLIGACAO VARCHAR(100), 
	DS_COMPOSICAO_COLIGACAO VARCHAR(100)
);

CREATE TABLE tb_votacao_candidato_munzona_2018_AP(
	NR_TURNO VARCHAR(1), 
	DT_ELEICAO DATE,
	SQ_CANDIDATO VARCHAR(12),
	NR_CANDIDATO VARCHAR(8), 
	DS_SIT_TOT_TURNO VARCHAR(20),
	QT_VOTOS_NOMINAIS INTEGER,
	NM_MUNICIPIO VARCHAR(50)
);

alter table tb_votacao_candidato_munzona_2018_AP RENAME DS_SIT_TOT_TURN to DS_SIT_TOT_TURNO


CREATE TABLE tb_despesas_contratadas_candidatos_2018_AP(
	ST_TURNO VARCHAR(1), 
	TP_PRESTACAO_CONTAS VARCHAR(50),
	SQ_PRESTADOR_CONTAS VARCHAR (15),
	SQ_CANDIDATO VARCHAR(12), 
	NR_CANDIDATO VARCHAR(8), 
	DS_ORIGEM_DESPESA VARCHAR(100), 
	DS_DESPESA VARCHAR(100), 	
	VR_DESPESA_CONTRATADA NUMERIC(10,2)
);

drop table tb_despesas_pagas_candidatos_2018_AP;
CREATE TABLE tb_despesas_pagas_candidatos_2018_AP(
	ST_TURNO VARCHAR(1), 
	TP_PRESTACAO_CONTAS VARCHAR(50),
	SQ_PRESTADOR_CONTAS VARCHAR (15),
	DS_FONTE_DESPESA VARCHAR(100), 
	DS_ORIGEM_DESPESA VARCHAR(100), 
	DS_DESPESA VARCHAR(100), 	
	VR_PAGTO_DESPESA NUMERIC(10,2)
);


\copy tb_despesas_pagas_candidatos_2018_AP
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;



----modelo fisico
--criando tabelas do modelo logico

--drop table candidato;
CREATE TABLE candidato(
	SQ_CANDIDATO VARCHAR(12), 
	NR_CANDIDATO VARCHAR(8), 
	NM_CANDIDATO VARCHAR(50), 
	NM_URNA_CANDIDATO VARCHAR(50), 
	DS_SITUACAO_CANDIDATURA  VARCHAR(20),
	DS_DETALHE_SITUACAO_CAND VARCHAR(50),
	DS_CARGO VARCHAR(30), 
	TP_AGREMIACAO VARCHAR(20), 
	NR_PARTIDO VARCHAR(3), 
	SQ_COLIGACAO VARCHAR(15),
	CONSTRAINT candidato_pk PRIMARY KEY(SQ_CANDIDATO)
);

--psql
'''
psql -d eleicao -U postgres

\copy candidato
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql

-------- partido
--drop table partido;
CREATE TABLE partido(
	NR_PARTIDO VARCHAR(3),  
	SG_PARTIDO VARCHAR(20),
	NM_PARTIDO VARCHAR(50),

	CONSTRAINT partido_pk PRIMARY KEY(NR_PARTIDO)
);

ALTER TABLE candidato ADD CONSTRAINT partido_fk FOREIGN KEY (NR_PARTIDO) 
		REFERENCES partido(NR_PARTIDO);
		
--psql
'''
\copy partido
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql

--select count(*) from voto


-------- coligacao
--drop table coligacao;
CREATE TABLE coligacao(
	SQ_COLIGACAO VARCHAR(12),  
	NM_COLIGACAO VARCHAR(100),
	DS_COMPOSICAO_COLIGACAO VARCHAR(100),

	CONSTRAINT coligacao_pk PRIMARY KEY(SQ_COLIGACAO)
);

ALTER TABLE candidato ADD CONSTRAINT coligacao_fk FOREIGN KEY (SQ_COLIGACAO) 
		REFERENCES coligacao(SQ_COLIGACAO);
		
--psql
'''
\copy coligacao
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql


-------- voto
DROP TABLE voto;
CREATE TABLE voto(
	NR_TURNO VARCHAR(1), 
	SQ_CANDIDATO VARCHAR(12),
	DT_ELEICAO DATE,
	DS_SIT_TOT_TURN VARCHAR(20),
	TOTAL_VOTOS INTEGER,

	CONSTRAINT voto_pk PRIMARY KEY(NR_TURNO, SQ_CANDIDATO),
	CONSTRAINT candidato_fk FOREIGN KEY (SQ_CANDIDATO) 
		REFERENCES candidato(SQ_CANDIDATO)
);

--psql
'''
\copy voto
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql



-------- despesas contratadas
--drop table despesas_contratadas;
CREATE TABLE despesas_contratadas(	
	ST_TURNO VARCHAR(1), 
	SQ_PRESTADOR_CONTAS VARCHAR (15),
	SQ_CANDIDATO VARCHAR(12), 
	DS_ORIGEM_DESPESA VARCHAR(100), 
	DS_DESPESA VARCHAR(100), 
	VR_DESPESA_CONTRATADA NUMERIC(10,2),
	ID_ SERIAL,

	CONSTRAINT despesaContratada_pk PRIMARY KEY(ID_),
	CONSTRAINT despesas_contratadas_fk FOREIGN KEY (SQ_CANDIDATO) 
		REFERENCES candidato(SQ_CANDIDATO)
);

--psql
'''
\copy despesas_contratadas
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql

--select count(*) from despesas_contratadas
--select * from despesas_contratadas limit 3;

-------- despesas pagas
--drop table despesas_pagas;
CREATE TABLE despesas_pagas(
	
	ST_TURNO VARCHAR(1),
	SQ_PRESTADOR_CONTAS VARCHAR (15), 
	DS_FONTE_DESPESA VARCHAR(100),
	DS_DESPESA VARCHAR(100),
	VR_PAGTO_DESPESA NUMERIC(10,2),
	SQ_CANDIDATO VARCHAR (12), 
	ID_ SERIAL,

	CONSTRAINT despesaPaga_pk PRIMARY KEY(ID_),
	CONSTRAINT candidato_fk FOREIGN KEY (SQ_CANDIDATO) 
		REFERENCES candidato(SQ_CANDIDATO)
);


--psql
'''
\copy despesas_pagas
from '/home/clbk/Área de trabalho/aqui/teste.csv'
with delimiter as ';' CSV HEADER;
'''
--fim_psql


