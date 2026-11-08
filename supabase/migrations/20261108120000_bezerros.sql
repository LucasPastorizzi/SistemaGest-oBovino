-- ============================================================
-- Controle de Bezerros — banco de dados
--
-- COMO USAR: Supabase → SQL Editor → New query → cole tudo → Run.
-- Pode rodar de novo sem medo: nada é apagado.
--
-- POR QUE ESTE BANCO EXISTE
--
-- O sistema guardava tudo só no navegador (localStorage). Isso funciona
-- bem e continua funcionando — é o que faz o sistema abrir sem internet,
-- no meio do pasto. O problema não é tamanho: cabem uns 20 mil bezerros
-- ali. O problema é que esses dados somem sem aviso quando o dono limpa
-- o cache do navegador, troca de celular, perde o celular, ou passa
-- tempo demais sem abrir (o Safari do iPhone descarta sozinho).
--
-- Este banco é a cópia que sobrevive a tudo isso. O navegador continua
-- sendo a verdade da tela; aqui é o lugar de onde os dados voltam.
-- ============================================================

-- ------------------------------------------------------------
-- BEZERROS
--
-- Uma linha por bezerro, com os mesmos campos que o app já usa. O `id`
-- é TEXT, e não uuid, porque o app gera o dele desde sempre
-- (Date.now() em base36 + aleatório) e os registros que já existem no
-- celular do dono precisam subir com o id que têm — senão a primeira
-- sincronização duplicaria tudo.
-- ------------------------------------------------------------
create table if not exists public.bezerros (
  id            text not null,

  -- De quem é o bezerro. O sistema é de um dono só hoje, mas a coluna
  -- existe desde o começo: é ela que a RLS usa, e acrescentar depois
  -- exigiria preencher linha por linha com o banco já em uso.
  dono          uuid not null references auth.users (id) on delete cascade,

  brinco        text not null,
  nome          text,
  mae           text,
  sexo          text,
  obs           text,

  nasc          date not null,
  apartar       date not null,

  apartado      boolean not null default false,
  data_apartado date,

  /*
   * Exclusão é marcada, não apagada.
   *
   * Se o dono apaga um bezerro no celular e a linha simplesmente some
   * daqui, a próxima sincronização baixa o registro de volta do servidor
   * — o bezerro "ressuscita". Marcando como removido, a informação de
   * que ele foi apagado também viaja.
   */
  removido      boolean not null default false,

  /*
   * Quem ganha quando o mesmo bezerro mudou nos dois lados.
   *
   * É um dono só, então conflito é raro — só acontece se ele editar no
   * celular sem sinal e no computador no mesmo intervalo. Nesse caso
   * vence a alteração mais recente. Simples, e honesto sobre o que faz.
   */
  atualizado_em timestamptz not null default now(),
  criado_em     timestamptz not null default now(),

  -- A chave é (dono, id): o id vem do navegador e só precisa ser único
  -- dentro do rebanho de cada dono.
  primary key (dono, id)
);

comment on table public.bezerros is
  'Bezerros no pé da vaca. Cópia de nuvem do que fica no navegador do dono.';
comment on column public.bezerros.removido is
  'Exclusão marcada, não apagada: sem isto o registro apagado volta na próxima sincronização.';

-- A sincronização pergunta sempre "o que mudou desde a última vez?".
create index if not exists bezerros_dono_atualizado
  on public.bezerros (dono, atualizado_em desc);

-- ------------------------------------------------------------
-- ATUALIZADO_EM NO SERVIDOR
--
-- O app manda o seu próprio `atualizado_em`, porque é ele quem sabe a
-- hora em que a alteração aconteceu — inclusive quando foi feita sem
-- sinal e só subiu horas depois. Este gatilho só entra quando o app não
-- manda nada, para a coluna nunca ficar nula ou velha.
-- ------------------------------------------------------------
create or replace function public.bezerros_tocar()
returns trigger
language plpgsql
as $$
begin
  if new.atualizado_em is null then
    new.atualizado_em := now();
  end if;
  return new;
end;
$$;

drop trigger if exists bezerros_tocar on public.bezerros;
create trigger bezerros_tocar
  before insert or update on public.bezerros
  for each row execute function public.bezerros_tocar();

-- ------------------------------------------------------------
-- SEGURANÇA
--
-- Cada dono só enxerga o próprio rebanho. Negado por padrão: sem estar
-- logado, toda consulta volta vazia — mesmo com a chave pública do
-- projeto em mãos, que fica visível no código do site.
-- ------------------------------------------------------------
alter table public.bezerros enable row level security;

drop policy if exists bezerros_le      on public.bezerros;
drop policy if exists bezerros_insere  on public.bezerros;
drop policy if exists bezerros_altera  on public.bezerros;
drop policy if exists bezerros_apaga   on public.bezerros;

create policy bezerros_le on public.bezerros
  for select to authenticated
  using (dono = auth.uid());

create policy bezerros_insere on public.bezerros
  for insert to authenticated
  with check (dono = auth.uid());

create policy bezerros_altera on public.bezerros
  for update to authenticated
  using (dono = auth.uid())
  with check (dono = auth.uid());

-- Apagar de verdade existe só para limpeza manual pelo painel. O app
-- nunca usa: ele marca `removido`.
create policy bezerros_apaga on public.bezerros
  for delete to authenticated
  using (dono = auth.uid());

-- ------------------------------------------------------------
-- CONFIGURAÇÃO DO DONO
--
-- Dias para apartar e dias de aviso. Uma linha por dono. Vive aqui, e
-- não junto dos bezerros, porque é ajuste da fazenda inteira — e porque
-- quando ele abrir num aparelho novo, o sistema precisa já vir com o
-- padrão dele, não com 210 dias de fábrica.
-- ------------------------------------------------------------
create table if not exists public.config (
  dono          uuid primary key references auth.users (id) on delete cascade,
  dias_apartar  smallint not null default 210 check (dias_apartar between 1 and 1000),
  dias_aviso    smallint not null default 15  check (dias_aviso between 0 and 365),
  atualizado_em timestamptz not null default now()
);

alter table public.config enable row level security;

drop policy if exists config_le     on public.config;
drop policy if exists config_grava  on public.config;

create policy config_le on public.config
  for select to authenticated
  using (dono = auth.uid());

create policy config_grava on public.config
  for all to authenticated
  using (dono = auth.uid())
  with check (dono = auth.uid());
