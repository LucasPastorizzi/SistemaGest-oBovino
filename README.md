# Controle de Bezerros

Sistema simples para registrar o nascimento dos bezerros e acompanhar o dia de apartar (desmamar), com aviso automático ao abrir.

Feito para ser fácil de usar: letras grandes, botões claros e cores que mostram a situação de cada bezerro.

**Acesse:** https://flypi-bezerros.vercel.app

## Funcionalidades

- Cadastro do bezerro: número/brinco, nome, mãe, sexo, dia que nasceu e observações
- Dia de apartar calculado sozinho (padrão de 210 dias, pode ser alterado)
- Aviso ao abrir com os bezerros perto de apartar ou que passaram da data
- Cores por situação: verde (no prazo), amarelo (perto), vermelho (passou da data)
- Filtros, busca e marcação de "Já apartei"
- Impressão da lista
- Cópia de segurança e recuperação (arquivo .json)

## Como funciona

É um site estático: um único `index.html`, sem build e sem framework.

**Os dados vivem no navegador** (localStorage). É isso que faz o sistema abrir e
funcionar no pasto, sem sinal — e continua sendo assim.

**E agora também na internet.** A cópia na nuvem existe porque o navegador sozinho perde tudo em situações comuns: limpar o
cache, trocar de celular, perder o celular, ou passar tempo demais sem abrir (o
Safari do iPhone descarta sozinho). Não é questão de espaço — cabem uns 20 mil
bezerros no navegador.

A regra é: **o navegador manda na tela, a nuvem é a cópia que sobrevive.** Nada
depende de internet para funcionar; quando há sinal, os dois lados se acertam.

### A sincronização

A cada sincronização o sistema baixa o rebanho inteiro e junta com o que está no
aparelho: o que está mais novo aqui sobe, o que está mais novo lá desce. Quando o
mesmo bezerro mudou dos dois lados, vence a alteração mais recente.

Acontece ao abrir, alguns segundos depois de cada alteração, e quando o sinal
volta. Se falhar, não acontece nada visível — os dados estão no
aparelho e sobem na próxima tentativa.

Bezerro excluído é **marcado**, não apagado: sem isso ele voltaria do servidor na
sincronização seguinte.

## Entrar: só o nome de usuário

Não há senha. A pessoa digita um nome de usuário que exista e entra. O aparelho
lembra: depois da primeira vez, abre direto, inclusive sem internet. A primeira
entrada em cada aparelho precisa de internet. O botão **Sair** fica no rodapé.

Cada usuário tem o seu rebanho. Por trás, cada um é uma conta no Supabase, e as
regras do banco (`dono = auth.uid()`) separam os dados. Usuário existente =
conta existente; não há lista de nomes no código.

**Cadastrar um usuário:** Authentication → Users → **Add user** → Create new
user, com o e-mail `nome@bezerros.flypi.com.br` (minúsculo, sem acento), a senha
de `CONTAS.senha` do `index.html` e **Auto Confirm User** marcado.

O usuário `bezerros` é a conta que já existia (`bezerros@flypi.com.br`) e fica
com o rebanho atual, tanto na nuvem quanto o que já estava no aparelho.

**O que isso custa, dito sem rodeio:** quem souber ou adivinhar um nome de
usuário vê e edita os bezerros dele. A senha comum está no código de uma página
pública e não protege nada; existe porque o Supabase exige uma.

**O que essas contas não alcançam:** não estão na tabela `equipe`, e toda tabela
do CRM da Flypi exige `eh_equipe()`. Nunca ponha uma delas na `equipe`.

Depois da primeira entrada, a conexão com a nuvem é melhor-esforço e falha calado: sem internet, com o projeto pausado ou
com a senha trocada no painel sem trocar no código, o sistema continua
funcionando inteiro com o que está no aparelho. O selo de situação simplesmente
não aparece — prometer "guardado na internet" sem estar guardando seria pior do
que não dizer nada.

## Ligar a nuvem

Enquanto não for configurada, o sistema roda só no navegador — igual ao que
sempre foi.

1. Criar um projeto no [Supabase](https://supabase.com) (região `sa-east-1`).
2. SQL Editor → New query → colar `supabase/migrations/20261108120000_bezerros.sql`
   → Run.
3. Authentication → Users → **Add user** → Create new user: criar uma conta por
   usuário (ver "Cadastrar um usuário"), marcando **Auto Confirm User** — sem isso
   ela nasce esperando um e-mail de confirmação e a entrada falha.
4. Authentication → Sign In / Providers → Email → desmarcar **Allow new users to
   sign up**. O app não tem tela de cadastro, mas a chave pública está no código
   e com ela dá para chamar `signUp` direto na API. Desligado, as contas passam
   a existir só quando alguém cria no painel.
5. Em `index.html`, preencher o bloco `NUVEM` com a URL e a chave pública do
   projeto (Project Settings → API).
6. Cadastrar os secrets `SUPABASE_URL` e `SUPABASE_CHAVE` no GitHub
   (Settings → Secrets and variables → Actions), para o job que mantém o banco
   acordado.

A chave pública pode ficar à vista no HTML — ela é feita para isso. Quem protege
os dados é a regra de acesso do banco (RLS), que só devolve os bezerros do dono
logado. **Nunca** colocar ali a chave `service_role`: essa ignora as regras.

### Se o dono já usa o sistema

A ordem importa. Ligar a nuvem **antes** de qualquer mudança de endereço: ele
abre o endereço antigo uma vez e o que está no celular sobe sozinho na primeira
sincronização. Só depois disso vale trocar o domínio — os dados do localStorage ficam presos ao
endereço antigo, e sem a nuvem no meio a troca começaria com o sistema vazio.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `index.html` | O sistema completo |
| `supabase/migrations/` | O SQL do banco (tabelas e permissões) |
| `.github/workflows/` | Job que impede o banco gratuito de dormir |
| `favicon.svg` / `favicon.ico` | Ícone da aba do navegador |
| `apple-touch-icon.png` | Ícone ao salvar na tela do celular |
| `og-image.png` | Imagem da prévia ao compartilhar o link (WhatsApp etc.) |

## Publicação

Hospedado na Vercel. Qualquer alteração enviada para a branch `main` é publicada automaticamente.

O projeto gratuito do Supabase é pausado depois de alguns dias sem uso, e o dono
passa semanas sem abrir fora da época de parição. O job em
`.github/workflows/manter-banco-acordado.yml` faz uma consulta a cada três dias
para evitar isso.

---

Desenvolvido por [Flypi Enterprise](https://flypi.com.br)
