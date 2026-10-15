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

É um site estático: um único `index.html`, sem servidor e sem banco de dados. Os dados ficam salvos no navegador de quem usa (localStorage), por isso a cópia de segurança é importante.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `index.html` | O sistema completo |
| `favicon.svg` / `favicon.ico` | Ícone da aba do navegador |
| `apple-touch-icon.png` | Ícone ao salvar na tela do celular |
| `og-image.png` | Imagem da prévia ao compartilhar o link (WhatsApp etc.) |

## Publicação

Hospedado na Vercel. Qualquer alteração enviada para a branch `main` é publicada automaticamente.

---

Desenvolvido por [Flypi Enterprise](https://flypi.com.br)
