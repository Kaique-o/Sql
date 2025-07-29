# 📁 Repositório de Queries ERP Sankhya

Este repositório tem como objetivo principal o **versionamento, organização e documentação de consultas SQL** utilizadas no sistema **ERP Sankhya**.

---

## ✨ Objetivo

Centralizar e manter o histórico de **queries personalizadas**, garantindo padronização, rastreabilidade e facilidade de manutenção ao longo do tempo. Ideal para equipes que trabalham com melhorias contínuas e integrações dentro da plataforma Sankhya.

---

## 📂 Estrutura do Repositório

As queries estão organizadas em pastas conforme:

- **Módulo** (ex: Vendas, Compras, Financeiro)
- **Funcionalidade específica** ou **finalidade da consulta**
- Cada query possui:
  - Comentários explicativos
  - Nome descritivo
  - Identificador único (opcional)

---

## 📎 Considerações Técnicas

- As queries seguem a sintaxe SQL padrão do **banco de dados Oracle**, utilizado pela Sankhya.
- **CTEs (Common Table Expressions)** não são utilizadas, pois **não são compatíveis com o extrator de dados** utilizado por Maria.
- Boas práticas de formatação e legibilidade devem ser respeitadas (ex: uso de aliases, indentação, convenções de nomenclatura).
- Sugestões de melhoria são bem-vindas via **Pull Request** ou **Issue**.

---

## ✅ Boas Práticas

- Nomeie os arquivos de forma clara e padronizada: `modulo__descricao.sql`
- Adicione comentários no topo explicando:
  - Objetivo da query
  - Campos principais retornados
  - Regras de negócio específicas (se houver)
- Utilize `-- TODO:` para sinalizar melhorias futuras

---

## 🙌 Colabore

Contribuições são sempre bem-vindas! Sinta-se à vontade para abrir uma *issue* com sugestões ou enviar um *pull request* com melhorias.

---

