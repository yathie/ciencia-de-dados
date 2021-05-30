library(tidyverse)
#1-remoção de colunas das tabelas de origem e jogar para o bd

#votacao_candidato_munzona_2018_AP <- read_csv2("/home/clbk/Área de trabalho/votacao_candidato_munzona_2018/votacao_candidato_munzona_2018_AP.csv", locale = locale(encoding = "ISO-8859-1"))

#despesas_contratadas_candidatos_2018_AP <- read_csv2("/home/clbk/Área de trabalho/prestacao_de_contas_eleitorais_candidatos_2018/despesas_contratadas_candidatos_2018_AP.csv", locale = locale(encoding = "UTF-8"))

#despesas_pagas_candidatos_2018_AP <- read_csv2("/home/clbk/Área de trabalho/prestacao_de_contas_eleitorais_candidatos_2018/despesas_pagas_candidatos_2018_AP.csv", locale = locale(encoding = "ISO-8859-1"))

#consulta_cand_2018_AP <- read_csv2("/home/clbk/Área de trabalho/consulta_cand_2018/consulta_cand_2018_AP.csv", locale = locale(encoding = "ISO-8859-1"))


#tabela com todos os candidatos aptos ou inaptos das Eleições Gerais Estaduais 2018 - AP
tb_consulta_cand_2018_AP <- distinct(consulta_cand_2018_AP, SQ_CANDIDATO, DS_CARGO, NR_CANDIDATO, NM_CANDIDATO, NM_URNA_CANDIDATO, DS_SITUACAO_CANDIDATURA, DS_DETALHE_SITUACAO_CAND, TP_AGREMIACAO, NR_PARTIDO, SG_PARTIDO, NM_PARTIDO, SQ_COLIGACAO, NM_COLIGACAO, DS_COMPOSICAO_COLIGACAO)
#salvar os dados num arquivo csv, para inserir no banco de dados por comando psql
write_csv2(tb_consulta_cand_2018_AP, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


#tabela com informação de votos para os candidatos em cada cidade do Amapá das Eleições Gerais Estaduais 2018 - AP
tb_votacao_candidato_munzona_2018_AP <- select(votacao_candidato_munzona_2018_AP, NR_TURNO, DT_ELEICAO, SQ_CANDIDATO, NR_CANDIDATO, DS_SIT_TOT_TURNO, QT_VOTOS_NOMINAIS, NM_MUNICIPIO) 

write_csv2(tb_votacao_candidato_munzona_2018_AP, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


#tabela com informação das diversas despesas contratadas por candidatos nas Eleições Gerais Estaduais 2018 - AP
tb_despesas_contratadas_candidatos_2018_AP <- select(despesas_contratadas_candidatos_2018_AP, ST_TURNO, TP_PRESTACAO_CONTAS, SQ_PRESTADOR_CONTAS, SQ_CANDIDATO, NR_CANDIDATO, DS_ORIGEM_DESPESA, DS_DESPESA, VR_DESPESA_CONTRATADA)
#Alteração necessária para que ao inserir os dados por comando psql não haja conflito com o tipo NUMERIC, no campo criado para esta coluna na tabela 'tb_despesas_contratadas_candidatos_2018_AP' no Postgres
tb_despesas_contratadas_candidatos_2018_AP$VR_DESPESA_CONTRATADA <-str_replace(tb_despesas_contratadas_candidatos_2018_AP$VR_DESPESA_CONTRATADA, ',', '.')

write_csv2(tb_despesas_contratadas_candidatos_2018_AP, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


#tabela com informação das diversas despesas pagas por candidatos nas Eleições Gerais Estaduais 2018 - AP
tb_despesas_pagas_candidatos_2018_AP <- select(despesas_pagas_candidatos_2018_AP, ST_TURNO, TP_PRESTACAO_CONTAS, SQ_PRESTADOR_CONTAS, DS_FONTE_DESPESA, DS_ORIGEM_DESPESA, DS_DESPESA, VR_PAGTO_DESPESA)

tb_despesas_pagas_candidatos_2018_AP$VR_PAGTO_DESPESA <-str_replace(tb_despesas_pagas_candidatos_2018_AP$VR_PAGTO_DESPESA, ',', '.')

write_csv2(tb_despesas_pagas_candidatos_2018_AP, file = "/home/clbk/Área de trabalho/aqui/teste.csv")
#fim criar tabelas de origem alteradas

#2-montar as tabelas do modelo logico
library(RPostgres)

con <- dbConnect(Postgres(),
                 user = "postgres",
                 password = "",
                 host = "localhost",
                 port = 5432,
                 dbname = "eleicao")

dbListTables(con)
'''
[1] "tb_consulta_cand_2018_ap"                  
[2] "tb_votacao_candidato_munzona_2018_ap"      
[3] "tb_despesas_contratadas_candidatos_2018_ap"
[4] "tb_despesas_pagas_candidatos_2018_ap"      
'''

##tabela candidato
#seleção dos campos das tabelas
candidato1 <- as_tibble(dbGetQuery(
  con,
  "select SQ_CANDIDATO, NR_CANDIDATO, NM_CANDIDATO, NM_URNA_CANDIDATO, DS_SITUACAO_CANDIDATURA, DS_DETALHE_SITUACAO_CAND, DS_CARGO, TP_AGREMIACAO, NR_PARTIDO, SQ_COLIGACAO 
  from tb_consulta_cand_2018_ap
  "
  ))

#salvar os dados num arquivo csv, para inserir no banco de dados por comando psql
write_csv2(candidato1, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


##tabela partido
#selecão dos partidos distintos
partido1 <- as_tibble(dbGetQuery(
  con,"
  select distinct(NR_PARTIDO), SG_PARTIDO, NM_PARTIDO
  from tb_consulta_cand_2018_ap
  "))

write_csv2(partido1, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


##tabela coligacao
#seleção das coligações distintas
coligacao1 <- as_tibble(dbGetQuery(
  con,"
  select distinct(SQ_COLIGACAO), NM_COLIGACAO, DS_COMPOSICAO_COLIGACAO
  from tb_consulta_cand_2018_ap
  "))

write_csv2(coligacao1, file = "/home/clbk/Área de trabalho/aqui/teste.csv")

##tabela voto
#tb_votacao_candidato_munzona_2018_ap
#seleção dos campos para a tabela voto, agrupando os campos para poder fazer o somatório dos  resultados de cada cidade e zona eleitoral do estado do Amapá por candidato, contidos na tabela de origem
voto1 <- as_tibble(dbGetQuery(
  con,"
  select NR_TURNO,SQ_CANDIDATO,DT_ELEICAO, DS_SIT_TOT_TURNO,
	sum(QT_VOTOS_NOMINAIS) TOTAL_VOTOS
	from tb_votacao_candidato_munzona_2018_ap
	group by (NR_TURNO,SQ_CANDIDATO, DT_ELEICAO, DS_SIT_TOT_TURNO)
  "))

write_csv2(voto1, file = "/home/clbk/Área de trabalho/aqui/teste.csv")



#tabela despesas_contratadas
#tb_despesas_contratadas_candidatos_2018_ap
#seleção dos campos para a tabela de despesas, com todas as tuplas, e ordenados primeiro pelo turno (ST_TURNO). e depois pela aequência do candidato (SQ_CANDIDATO)
despesas_contratadas1 <- as_tibble(dbGetQuery(
  con,"
  select ST_TURNO, SQ_PRESTADOR_CONTAS, SQ_CANDIDATO, DS_ORIGEM_DESPESA, DS_DESPESA, VR_DESPESA_CONTRATADA

	from tb_despesas_contratadas_candidatos_2018_ap
	order by (ST_TURNO, SQ_CANDIDATO)
  "))
#adicionada uma coluna, que vai servir como chave primária
despesas_contratadas2 <- mutate(despesas_contratadas1, ID_ = 1)

#renumerar ID_
despesas_contratadas2$ID_ <- seq.int(nrow(despesas_contratadas2))

#ateração necessária para que ao exportar a variável 'despesas_contratadas2', não haja conflito ao inserir os dados no banco por psql.
#ao exportar o campo 'vr_despesa_contratada' fica com vírgula nos dados decimais. Na criação da tabela 'despesas_contratadas' no modelo lógico, o campo 'vr_despesa_contratada' é definido como NUMERIC. Assim, ao inserir o csv aqui gerado e tendo o campo 'vr_despesa_contratada' com vírgula, na tabela criada no Postgres, ocorria erro porque os dados não eram reconhecidos como numéricos.
despesas_contratadas2$vr_despesa_contratada <- as.character(despesas_contratadas2$vr_despesa_contratada)

write_csv2(despesas_contratadas2, file = "/home/clbk/Área de trabalho/aqui/teste.csv")


#tabela despesas_pagas
#criada uma tabela temporária (tb_aux) com os valores distintos de sequência do prestador de contas (SQ_PRESTADOR_CONTAS)
despesas_pagas1 <- as_tibble(dbGetQuery(
  con,"
  select distinct(SQ_PRESTADOR_CONTAS), SQ_CANDIDATO into tb_aux
from tb_despesas_contratadas_candidatos_2018_ap;
  "))

#seleção de todos os dados da tabela 'tb_despesas_pagas_candidatos_2018_ap', de acordo com os campos especificados, adicionando uma coluna da tabela 'tb_aux', para todos que forem correspondentes
despesas_pagas2 <- as_tibble(dbGetQuery(
  con,"
  select dp.ST_TURNO, dp.SQ_PRESTADOR_CONTAS, dp.DS_FONTE_DESPESA,
dp.DS_DESPESA, dp.VR_PAGTO_DESPESA, tb_aux.SQ_CANDIDATO
from tb_despesas_pagas_candidatos_2018_ap dp
left join tb_aux
on dp.SQ_PRESTADOR_CONTAS = tb_aux.SQ_PRESTADOR_CONTAS;
  "))


despesas_pagas2 <- mutate(despesas_pagas2, ID_ = 1)

#renumerar ID_
despesas_pagas2$ID_ <- seq.int(nrow(despesas_pagas2))

despesas_pagas2$vr_pagto_despesa<- as.character(despesas_pagas2$vr_pagto_despesa)

write_csv2(despesas_pagas2, file = "/home/clbk/Área de trabalho/aqui/teste.csv")

########### análises ##########
'''
con <- dbConnect(Postgres(),
                 user = "postgres",
                 password = "",
                 host = "localhost",
                 port = 5432,
                 dbname = "eleicao")
dbListTables(con)
 [5] "partido"                                   
 [6] "candidato"                                 
 [7] "coligacao"                                 
 [8] "voto"                                      
 [9] "despesas_contratadas"                      
[10] "despesas_pagas" 
'''
#####Q1 – É possível relacionar gasto na campanha com quantidade de votos?
#selecao dos candidatos aptos à eleicao
dbListFields(con, "candidato")

as_tibble(dbGetQuery(
  con,"
  select distinct ds_situacao_candidatura from candidato
  "))

#todos os candidatos que tem despesas contratadas menos os candidatos que possuem e são inaptos
candidatos_aptos1 <- as_tibble(dbGetQuery(
  con,"
  select distinct sq_candidato into tb_aux
  from despesas_contratadas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO'
  "))
#313

#seleção do somatório das despesas dos candidatos aptos no primeiro turno 
candidatos_aptos2 <- as_tibble(dbGetQuery(
  con,"
  select aux.sq_candidato, 
  sum(d.vr_despesa_contratada) total_contratada into tb_aux2
  from tb_aux aux left join despesas_contratadas d
  on(aux.sq_candidato = d.sq_candidato)
    where d.st_turno = '1'
  group by (aux.sq_candidato);
  "))
#311

#todos os candidatos aptos + votos recebidos no 1o turno
candidatos_aptos3 <- as_tibble(dbGetQuery(
  con,"
   select aux.sq_candidato
  ,aux.total_contratada
  ,v.total_votos
  from tb_aux2 aux left join voto v
  on(aux.sq_candidato = v.sq_candidato);
  "))

#grafico votosXdespesas contratadas
ggplot()+
  geom_line(candidatos_aptos3,mapping = aes(x = `total_votos` , y =  `total_contratada`), colour = "orange") +
  scale_y_continuous(n.breaks = 8) +
  scale_x_continuous(n.breaks = 9) +
  labs(candidatos_aptos3,title = "Despesas contratadas 1° turno - Eleições Estaduais 2018 AMAPÁ \n Candidatos aptos", x = "Votos", y = "Total das despesas contratadas")+
  theme_minimal()+
  theme(axis.title = element_text(size=14), plot.title = element_text(size=16))





'''sql
  select count(*) from voto;
  where nr_turno = '1'
  --542 receberam votos no promeiro turno
  
  select count(*) from candidato
  where ds_situacao_candidatura = 'APTO';
  --576 estavam aptos
  
  select count(distinct sq_candidato)
  from despesas_contratadas
  where st_turno = '1';
  --339 tiveram despesas contratadas no primeiro turno
  
   select sq_candidato from voto
 where nr_turno = '1'
 except
 select sq_candidato from candidato
 where ds_situacao_candidatura='APTO'
 --1 candidato inapto recebeu voto
 --30000620073
 
 
 select total_votos
 from voto
 where sq_candidato = '30000620073'
 --78 votos para candidato inapto
  
'''
#considerando todos os candidatos que tiveram votos e que nao tiveram despesas contratadas
candidatos_aptos4 <- as_tibble(dbGetQuery(
  con,"
   select v.sq_candidato,
v.total_votos,
sum(d.vr_despesa_contratada) total_contratada 
from voto v left join despesas_contratadas d
on( v.sq_candidato =  d.sq_candidato)
where v.nr_turno = '1'
group by(v.sq_candidato,  v.total_votos);

  "))
#grafico2 votosXdespesas contratadas
ggplot()+
  geom_line(candidatos_aptos4,mapping = aes(x = `total_votos` , y =  `total_contratada`), colour = "purple") +
  scale_y_continuous(n.breaks = 8) +
  scale_x_continuous(n.breaks = 9) +
  labs(candidatos_aptos4,title = "Despesas contratadas 1° turno - Eleições Estaduais 2018 AMAPÁ \n Todos os candidatos que receberam votos", x = "Votos", y = "Total das despesas contratadas")+
  theme_minimal()+
  theme_minimal()+
  theme(axis.title = element_text(size=14), plot.title = element_text(size=16))






---despesas pagas
candidatos_paga1 <-as_tibble(dbGetQuery(
  con,"
    select voto.total_votos, aux.sq_candidato, aux.total_paga
  from voto right join
  
  (select d.sq_candidato, 
  sum(d.vr_pagto_despesa) total_paga 
  from  despesas_pagas d
    where d.st_turno = '1' and d.sq_candidato in
	(select distinct sq_candidato
  from despesas_pagas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO')
  group by (d.sq_candidato)) aux
  
   on(aux.sq_candidato = voto.sq_candidato);
  "))


#grafico1 votosXdespesas pagas
ggplot()+
  geom_line(candidatos_paga_1,mapping = aes(x = `total_votos` , y =  `total_paga`), colour = "orange") +
  scale_y_continuous(n.breaks = 8) +
  scale_x_continuous(n.breaks = 9) +
  labs(candidatos_paga_1,title = "Despesas pagas 1° turno - Eleições Estaduais 2018 AMAPÁ \n Todos os candidatos aptos", x = "Votos", y = "Total das despesas pagas")+
  theme_minimal()+
  theme(axis.title = element_text(size=14), plot.title = element_text(size=16))



#considerando todos os candidatos que tiveram votos e que nao tiveram despesas pagas
candidatos_pagas2 <- as_tibble(dbGetQuery(
  con,"
 select v.sq_candidato,
v.total_votos,
sum(d.vr_pagto_despesa) total_paga
from voto v left join despesas_pagas d
on( v.sq_candidato =  d.sq_candidato)
where v.nr_turno = '1'
group by(v.sq_candidato,  v.total_votos);

  "))
#grafico2 votosXdespesas contratadas
ggplot()+
  geom_line(candidatos_pagas2,mapping = aes(x = `total_votos` , y =  `total_paga`), colour = "purple") +
  scale_y_continuous(n.breaks = 8) +
  scale_x_continuous(n.breaks = 9) +
  labs(candidatos_pagas2,title = "Despesas pagas 1° turno - Eleições Estaduais 2018 AMAPÁ \n Todos os candidatos que receberam votos", x = "Votos", y = "Total das despesas contratadas")+
  theme_minimal()+
  theme(axis.title = element_text(size=14), plot.title = element_text(size=16))





#refinando: anos continuos? barras simbolizando cada valor de moeda (Denominação)
#position = position_dodge() ->  Isso significa que as barras são dispostas em grupos, uma do lado da outra. Caso esse argumento não fosse definido, as barras estariam uma sobre a outra, de forma empilhada
ggplot(data = conjunto_de_analise)+
  geom_bar(stat = "identity", position = position_dodge(), mapping = aes(x = as.factor(Ano), y = `Quantidade Média`, fill = Denominação))+
  scale_y_continuous(n.breaks = 8) +
  labs(x = "Ano", y = "Quantidade Média em Circulação") +
  theme(axis.title = element_text(size=10), plot.title = element_text(size=12, face="bold")) +
  ggtitle("Nosso primeiro gráfico de barras")
#mesmo grafico, mas em linhas
ggplot(data = conjunto_de_analise) + 
  geom_line(mapping = aes(x = as.factor(Ano), y = `Quantidade Média`, group = Denominação, colour = Denominação)) +
  scale_y_continuous(n.breaks = 8) +
  labs(x = "Ano", y = "Quantidade Média em Circulação") +
  theme(axis.title = element_text(size=10), plot.title = element_text(size=12, face="bold")) +
  ggtitle("Nosso primeiro gráfico de linha")



#####Q2 -  Qual o menor e maior investimento na campanha entre os candidatos?
#maior investmento
'''
--maior investimento na campanha - despesas contratadas
--2729899.49 candidato 30000620103
--usado no r
select max(ss.total_contratada) maior_valor, ss.sq_candidato

from (
  select voto.total_votos, aux.sq_candidato, aux.total_contratada
  from voto right join
  
  (select d.sq_candidato, 
  sum(d.vr_despesa_contratada) total_contratada
  from  despesas_contratadas d
    where d.st_turno = '1' and d.sq_candidato in
	(select distinct sq_candidato
  from despesas_contratadas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO')
  group by (d.sq_candidato)) aux
  
   on(aux.sq_candidato = voto.sq_candidato)
) ss
group by (ss.sq_candidato)
having max(ss.total_contratada) > 0
order by(maior_valor) desc

limit 1
--quem é o candidato com maior investimento?
--DAVID SAMUEL ALCOLUMBRE TOBELEM para o cargo de governador
select * from candidato
where sq_candidato = '30000620103'
--ele foi eleito?
--nao eleito
select * from voto
where sq_candidato = '30000620103'
'''


#####Q3 – Qual é a média de valor nas campanhas por cada partido?
media_partido <- as_tibble(dbGetQuery(
  con,"
select avg(ss.vlr) media, ss.nr_partido, partido.sg_partido
from partido inner join 
(
	select despesas_contratadas.vr_despesa_contratada vlr,
aux.nr_partido
from despesas_contratadas left join
(
select c.sq_candidato, p.nr_partido
from candidato c join partido p
on( c.nr_partido =  p.nr_partido)
) aux
on(despesas_contratadas.sq_candidato = aux.sq_candidato)
where despesas_contratadas.st_turno = '1'
) ss
	on(partido.nr_partido = ss.nr_partido)
group by (ss.nr_partido, partido.sg_partido)
order by (media)

  "))

#graficoValor médio de despesas contratadas por partido político 1o turno 
  ggplot(data = media_partido)+
    geom_bar(stat = "identity", position = position_dodge(), mapping = aes(x = nr_partido, y = media, fill= sg_partido)) +
    scale_y_continuous(n.breaks = 8) +
    labs(x = "N° do partido", y = "Média de despesas contratadas", fill= "Sigla") +
    theme(axis.title = element_text(size=14), plot.title = element_text(size=16, face="bold")) +
    ggtitle("Valor médio de despesas contratadas por partido político")+
    theme_linedraw()
    
  







