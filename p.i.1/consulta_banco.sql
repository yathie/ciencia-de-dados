

----sql
--seleção dos campos para a tabela 'candidato' - usada no R
select SQ_CANDIDATO, NR_CANDIDATO, NM_CANDIDATO, NM_URNA_CANDIDATO, DS_SITUACAO_CANDIDATURA, DS_DETALHE_SITUACAO_CAND, DS_CARGO, TP_AGREMIACAO, NR_PARTIDO, SQ_COLIGACAO 
  from tb_consulta_cand_2018_ap;

--selecão dos partidos distintos para a tabela 'partido' - usado no r
  select distinct(NR_PARTIDO), SG_PARTIDO, NM_PARTIDO
  from tb_consulta_cand_2018_ap;

--seleção das coligações distintas para a tabela 'coligacao' - usado no r
  select distinct(SQ_COLIGACAO), NM_COLIGACAO, DS_COMPOSICAO_COLIGACAO
  from tb_consulta_cand_2018_ap;
  
--seleção dos campos para a tabela voto, agrupando os campos para poder fazer o somatório dos  resultados de cada cidade e zona eleitoral do estado do Amapá por candidato, contidos na tabela de origem
--usado no r
  select NR_TURNO,SQ_CANDIDATO,DT_ELEICAO, DS_SIT_TOT_TURNO,
	sum(QT_VOTOS_NOMINAIS) TOTAL_VOTOS
	from tb_votacao_candidato_munzona_2018_ap
	group by (NR_TURNO,SQ_CANDIDATO, DT_ELEICAO, DS_SIT_TOT_TURNO)

--seleção dos campos para a tabela 'despesas_contratadas', com todas as tuplas, e ordenados primeiro pelo turno (ST_TURNO). e depois pela sequência do candidato (SQ_CANDIDATO)
--usado no r
  select ST_TURNO, SQ_PRESTADOR_CONTAS, SQ_CANDIDATO, DS_ORIGEM_DESPESA, DS_DESPESA, VR_DESPESA_CONTRATADA

	from tb_despesas_contratadas_candidatos_2018_ap
	order by (ST_TURNO, SQ_CANDIDATO)
	
--tabela 'despesas_pagas'
--criada uma tabela temporária (tb_aux) com os valores distintos de sequência do prestador de contas (SQ_PRESTADOR_CONTAS)
  select distinct(SQ_PRESTADOR_CONTAS), SQ_CANDIDATO into tb_aux
from tb_despesas_contratadas_candidatos_2018_ap;
--#seleção de todos os dados da tabela 'tb_despesas_pagas_candidatos_2018_ap', de acordo com os campos especificados, adicionando uma coluna da tabela 'tb_aux', para todos que forem correspondentes
--usado no r
  select dp.ST_TURNO, dp.SQ_PRESTADOR_CONTAS, dp.DS_FONTE_DESPESA,
dp.DS_DESPESA, dp.VR_PAGTO_DESPESA, tb_aux.SQ_CANDIDATO
from tb_despesas_pagas_candidatos_2018_ap dp
left join tb_aux
on dp.SQ_PRESTADOR_CONTAS = tb_aux.SQ_PRESTADOR_CONTAS;

--remocao da tabela temporária
drop table tb_aux;



-------- analises --------
--selecao dos candidatos aptos à eleicao
  select distinct ds_situacao_candidatura from candidato
--todos os candidatos que tem despesas contratadas menos os candidatos que possuem e são inaptos
--313 candidatos possuem despesas contratadas e são aptos à eleicao (considerando os dois turnos)
  select distinct sq_candidato into tb_aux
  from despesas_contratadas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO'
--seleção do somatório das despesas dos candidatos aptos no primeiro turno 
--311 candidatos possuem despesas contratadas e são aptos à eleicao e participaram do 1o turno
  select aux.sq_candidato, 
  sum(d.vr_despesa_contratada) total_contratada into tb_aux2
  from tb_aux aux left join despesas_contratadas d
  on(aux.sq_candidato = d.sq_candidato)
    where d.st_turno = '1'
  group by (aux.sq_candidato);
  
drop table tb_aux2;

--#todos os candidatos aptos com despesas contratadas no primeiro turno+ votos recebidos no 1o turno
   select aux.sq_candidato
  ,aux.total_contratada
  ,v.total_votos
  from tb_aux2 aux left join voto v
  on(aux.sq_candidato = v.sq_candidato);
  
 
  select count(*) from voto;
  where nr_turno = '1'
  --542 receberam votos no primeiro turno
  
  select count(*) from candidato
  where ds_situacao_candidatura = 'APTO';
  --576 estavam aptos
  
  select count(distinct sq_candidato)
  from despesas_contratadas
  where st_turno = '1';
  --339 tiveram despesas contratadas no primeiro turno(aptos ou não)
  
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
  
--#considerando todos os candidatos que tiveram votos e que nao tiveram despesas contratadas
   select v.sq_candidato,
v.total_votos,
sum(d.vr_despesa_contratada) total_contratada 
from voto v left join despesas_contratadas d
on( v.sq_candidato =  d.sq_candidato)
where v.nr_turno = '1'
group by(v.sq_candidato,  v.total_votos);

drop table tb_aux;


--sobre tabela 'despesas_pagas'--

--total de candidatos com despesas pagas
---333 candidatos diferentes
select count(distinct sq_candidato) from  despesas_pagas
--#todos os candidatos que tem despesas pagas menos os candidatos que possuem e são inaptos
--307 candidatos aptos que tem despesas pagas
select distinct sq_candidato
  from despesas_pagas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO'
--somar despesas pagas dos candidatos aptos
--305 candidatos 1o turno
--sq_candidato e total_paga
select d.sq_candidato, 
  sum(d.vr_pagto_despesa) total_paga 
  from  despesas_pagas d
    where d.st_turno = '1' and d.sq_candidato in
	(select distinct sq_candidato
  from despesas_pagas
  except
  select sq_candidato from candidato
  where ds_situacao_candidatura = 'INAPTO')
  group by (d.sq_candidato);
--#todos os candidatos aptos + votos recebidos no 1o turno
--usado no r
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

--considerando todos os candidatos que tiveram votos e que nao tiveram despesas contratadas
 --542 - ok
 select v.sq_candidato,
v.total_votos,
sum(d.vr_pagto_despesa) total_paga
from voto v left join despesas_pagas d
on( v.sq_candidato =  d.sq_candidato)
where v.nr_turno = '1'
group by(v.sq_candidato,  v.total_votos);

--Q2 – Qual o menor e maior investimento na campanha entre os candidatos?
--maior investimento na campanha - despesas contratadas
--2729899.49 candidato 30000620103
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
--menor despesa
--6,6 30000625385
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
order by(maior_valor)

limit 1
--quem é o candidato com menor investimento?
--ARIVALDO DOS SANTOS SERRA para o cargo de deputado estadual
select * from candidato
where sq_candidato = '30000625385'
--ele foi eleito?
--suplente
select * from voto
where sq_candidato = '30000625385'
  
  
  
  
  
  
--Q3- Qual é a média de valor nas campanhas por cada partido?
--relacionar despesa contratada com partidos - primeiro candidato com partido (1o turno)
--9780 linhas
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
--apenas para conferir a qatd de linhas trazidas anteriormente
--9780 linhas
select count(*) from despesas_contratadas
where despesas_contratadas.st_turno = '1'
--somatorio dos valores por partido + sigla do partido
--usado no r
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

--partido com maior gasto medio
select* from partido where nr_partido ='51'

  