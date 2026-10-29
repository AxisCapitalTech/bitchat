# AUDITORIA INDEPENDENTE — MESHPRIV iOS + AXIS PAY MATRIX (29/10/2026)

## INSTRUÇÕES AO CLAUDE
Você é revisor independente sênior de segurança, iOS/Swift, BLE mesh e arquitetura de pagamentos.
**Analise código real, não confie nos resumos de PRs ou nas afirmações do assistente.**
Não produza aprovação geral sem confirmar por arquivos, linhas, fluxos de dados e testes.
Não faça merge, deploy, push, alterações de branches, ativações de pagamentos ou alterações na criptografia.
Se não puder compilar/testar, separe achados demonstráveis de hipóteses.

## IDENTIDADE DA AMOSTRA
- Projeto: MeshPriv — mensagens BLE + Axis Pay sandbox no mesmo app, interface Matrix.
- Fork: https://github.com/AxisCapitalTech/bitchat
- Snapshot de **código** (antes de adicionar estes documentos de auditoria): `ea282f783c73047eb9cadb55880f7e2181559735`.
- PR da interface: https://github.com/AxisCapitalTech/bitchat/pull/5
- Branch da interface: `feature/meshpriv-matrix-shell-wallet-sandbox`.
- Branch auditável com este roteiro: `audit/meshpriv-claude-20261029`.
- PR5 base `phase2/03-offline-tests-and-cleanup` (`7366a55afdd53ca7f026dd3c0c1cc3348e46c9ae`).
- Branch principal `main` não recebeu estas alterações.
- Desenvolvimento em estágios: PR #1 (marca), PR #2 (roteamento BLE e startup), PR #3 (remover inicialização online residual), PR #4 (limpeza e testes), PR #5 (shell Matrix e carteira sandbox).
- Android NÃO incluído: o fork `AxisCapitalTech/bitchat-android` ainda não havia sido localizado na conta.

## OBJETIVO ACORDADO
Um só app, PT-BR/EN e Matrix preto/verde:
1. Conversas privadas via Bluetooth LE mesh; manter Noise e wire protocol upstream; sem tráfego Nostr/Internet de mensagens.
2. Lista de peers BLE e relay, com abertura de conversas sem alterar o rádio ou a criptografia.
3. Carteira Axis Pay integrada, ainda **sandbox local sem dinheiro real**.
4. No futuro pagamentos online por blockchain (pagamentos devem ser isolados dos canais de mensagens).
**A versão atual NÃO é 100% offline no binário:** fontes Nostr/Tor remanescentes ainda estão no projeto; não há prova dinâmica de ausência de tráfego de rede.

## MUDANÇAS CRÍTICAS NO PR5
- `bitchat/Views/MeshPrivMatrixShell.swift` (NOVO): três abas, painel nearby, demonstração wallet, CoreImage QR.
- `bitchat/Views/ContentView.swift`: usa mainContent/chatContent e a navegação iOS.
- `bitchat/ViewModels/ChatViewModel.swift`: wipe do histórico local da wallet na rotina de panic clear.
- `MESHPRIV_MATRIX_PAY_INTEGRATION.md`: design/limitações.
Contexto anterior dos PRs: `bitchat/ViewModels/ChatViewModelBootstrapper.swift`, `bitchat/App/AppRuntime.swift`, `bitchat/Services/MessageRouter.swift`, `bitchat/Services/NetworkActivationService.swift` e rotas Nostr/Gateway.

## CHECKLIST PRIORITÁRIO
### P0 — Segurança / dinheiro
- Não deve existir nenhum caminho que marque **pagamento real** como confirmado baseado em flag local, QR, captura de tela ou simulação.
- Confirmar que `meshpriv-demo://` NÃO é URI Solana pagável, nem contém wallet real; não há fetch/RPC/assinatura financeira nesta aba.
- Segredos: chaves privadas, seed phrases e dados de pagamento não podem entrar em UserDefaults, logs nem mensagens públicas.
- O panic wipe realmente remove `meshpriv.pay.sandbox.charges.v1` em execução normal? Verificar todos os UserDefaults/AppStorage domains e eventuais rehydrations; testá-lo.
- Revisar ações online residuais: Nostr/Tor, WebSockets, URLSession, geohash, relays, bridge e app extensions. Tráfego de mensagens deve ficar estritamente BLE.
- Exposição de metadados e privacy banners: NÃO confundir canais públicos mesh com conversas privadas E2EE. Reavaliar deep links, QR de verificação e cryptographic contexts: preservar interoperabilidade.
- Não há funcionalidade de produção comercial; sem custódia, câmbio, processamento real, webhooks ou faturamento.

### P1 — Interface e fluxos SwiftUI
- Verificar compilação macOS e iOS; import de CoreImage, UIKit, CIFilterBuiltins e uso de availability.
- `ContentView` tem sheets e overlays associados a root view: ao trocar abas, conversas, voice recording e panic wipe sobrevivem? Does switching tabs cause data loss or force dismiss sheets?
- Verificar se selecionar peers em Mesh e chamar `peerListModel.startConversation(with:)` realmente mostra a DM (binding showSidebar e selectedPrivatePeerID) sem corrida no tab switch.
- Acessibilidade VoiceOver, Dynamic Type, contraste, tratamento de tamanho de tela, PT-BR/EN.
- QR real renderizado (não somente texto), precisão de valor, inclusão de id e token e não-expiração. Não divulgar QR como pagável.
- Identidade Matrix original sem uso indevido de propriedade intelectual.
- `MeshPrivSection` e state variables para macOS/iOS: compilação condicional adequada.
- Dados dos usuários reais não devem ser inventados nem povoar status de pagamento.
- Reavaliar a ausência de integração conversa → pedido de cobrança (o botão "Pagar contato" ainda não foi ligado à carteira).

### P1 — Rádio e segurança do upstream
- Verificar permanência de Noise E2EE e wire protocol, forwarding e dedup, fragmentação, store-and-forward, fingerprints, trust store e QR assinado.
- Testar Android↔iOS e BLE background/foreground; nada dessas condições foi validado neste fork.
- O primeiro fork iOS é Unlicense, mas há dependências e a base Android GPLv3: conferir redistribuição e requisitos da loja.

### P2 — CI / manutenção
- A proteção estática de inicialização online passou no commit de PR5, mas não substitui auditoria estática e dinâmica de dependências.
- Status da execução de Build & Test e do Periphery pode mudar; verificar os links e a conclusão, não confiar neste resumo.
- Bases de teste alteradas: PR4 desativou cinco testes Nostr/geohash; avaliar se ainda há cenários válidos de BLE ou regressões em features mantidas.
- Revisar warnings do Periphery sem mascarar findings.

## FALHAS CONHECIDAS / NÃO APROVADO
- Sem teste de dispositivo físico e sem validação Android.
- Remoção completa de Tor/Nostr das dependências ainda pendente.
- Compilação e testes do PR5 não estavam concluídos no momento de montar o pacote.
- Branch PR4 anterior: Build & Test falhou no gate de desempenho, apesar de simulador e SwiftLint aprovados; revisar log.
- Integração real de pagamentos NÃO implementada: sem backend, confirmação blockchain, cotação, wallet connection, conciliação ou compliance.
- O painel web independente `https://axis-pay-demo.vercel.app` é outra demo sandbox, não é o código nativo incluído neste ZIP.

## LINKS DE EVIDÊNCIAS (verificar status atualizado)
- PR 1: https://github.com/AxisCapitalTech/bitchat/pull/1
- PR 2: https://github.com/AxisCapitalTech/bitchat/pull/2
- PR 3: https://github.com/AxisCapitalTech/bitchat/pull/3
- PR 4: https://github.com/AxisCapitalTech/bitchat/pull/4
- PR 5: https://github.com/AxisCapitalTech/bitchat/pull/5
- CI PR5 Build & Test: https://github.com/AxisCapitalTech/bitchat/actions/runs/40917944166
- CI PR5 Offline Guard: https://github.com/AxisCapitalTech/bitchat/actions/runs/40917944293
- CI PR5 Dead Code: https://github.com/AxisCapitalTech/bitchat/actions/runs/40917944160
- CI PR4 Build & Test: https://github.com/AxisCapitalTech/bitchat/actions/runs/40684226319

## FORMATO DE SAÍDA EXIGIDO AO CLAUDE
1. **Veredito**: APROVADO / APROVADO COM RESSALVAS / REPROVADO e se a compilação foi realmente executada.
2. Tabela de achados: ID, severidade P0/P1/P2, arquivo+linha, evidência, causa raiz, impacto, correção mínima, risco de regressão.
3. Matriz de funcionalidades (confirmadas pelo código; demonstrativas; não implementadas; não testadas).
4. Plano de testes: comandos, simuladores, dois/três aparelhos, captura/inspeção de egress, link BLE, panic wipe.
5. Patch mínimo em diff (SOMENTE se testado ou claramente indicado como proposta); não reescrever nem trocar protocolos.
6. Lista de bloqueadores para merge, publicação, pagamentos reais e afirmação de 100% offline.

## REGRA FINAL
Não usar a palavra "seguro", "auditado" ou "pronto" sem evidências. Não criar novo protocolo criptográfico. Não ocultar regressões com remoção indiscriminada dos testes.
