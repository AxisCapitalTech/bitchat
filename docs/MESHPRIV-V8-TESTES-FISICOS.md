# MeshPriv — Marco V8→V9: testes físicos sem internet

**Estado em 30/10/2026:** testes SwiftPM, simulador e Release
universais passaram no commit `35e05ba3`. As quatro capturas SwiftUI foram
revisadas visualmente (renderização corrigida), mas **não representam prova de
comunicação Bluetooth**, e as correções posteriores de idioma/prévias ainda
requerem uma nova CI.

## Pré-condições
- Duas instalações nativas iOS assinadas em aparelhos de teste, de preferência
  três para testar relay. Não usar link Vercel: a interface web não tem BLE.
- iOS atualizado; permissões Bluetooth concedidas em cada aparelho.
- Sem Internet: desligar Wi‑Fi e dados móveis e confirmar que Bluetooth está
  LIGADO manualmente (o Modo Avião pode desligá-lo).
- Não inserir senhas reais, frases-semente ou fundos reais no Axis Pay.
- No resultado, registrar: aparelhos, versões de iOS, commit/build,
  permissões, observações e capturas **anonimizadas**.

## Matriz de testes bloqueantes
| ID | Execução | Critério de aprovação |
|---|---|---|
| B01 | Abrir A e B lado a lado, sem Wi‑Fi/dados móveis | Cada aparelho descobre o outro por BLE; nenhum relay Internet |
| B02 | A abre o contato B e envia mensagem privada | B recebe texto correto uma única vez; interface abre a DM verdadeira |
| B03 | B responde, alternando telas Conversas/Radar/Perfil | Histórico e conteúdo permanecem corretos no canal certo |
| B04 | Observar handshake Noise com logs não sensíveis | DM sem downgrade para texto claro; sessão autêntica |
| B05 | A, B, C em linha, A fora de alcance de C, B intermediário | Entrega de relay conforme capacidade upstream; sem duplicatas |
| B06 | Fechar/abrir app, Bluetooth desligado e religado | Recuperação correta, sem falsa contagem de dispositivos |
| B07 | Receber mensagem durante outras abas e retorno de background | Estado consistente; observar restrições reais de iOS |
| B08 | Tocar em apagar dados em emergência e cancelar | Nenhum dado apagado sem confirmação |
| B09 | Confirmar pânico em A | Histórico local e identidade eliminados; antigas chaves não restabelecidas |
| B10 | Carteira: criar QR USDC e USDT no sandbox | Apenas `meshpriv-demo://`, sem QR pagável nem transação |
| B11 | Monitorar egress de rede no fluxo de mensagens | Sem HTTP, WebSocket, Nostr, Tor, DNS ou geolocalização para mensageria |
| B12 | Comparar Conversas/Radar/Carteira/Perfil com referência aprovada | Visual próximo com métricas honestas; sem contas, locais, saldos fabricados |

## Bloqueios antes de distribuição
1. CI verde no commit da instalação: Build Release, todos os testes Swift,
   iOS simulator, SwiftLint, guard offline, performance >= 2.400 msg/s.
2. Triage de **46 avisos Periphery** do commit anterior; não remover
   componentes BLE/Noise apenas para silenciar o scanner.
3. Imagens nativas 393×780 verificadas quanto a corpo não vazio, PT-BR,
   textos e limites seguros em iPhone com Dynamic Type.
4. Conferir arquivo `Info.plist`: razão clara para usar Bluetooth;
   inspecionar entitlements antes de assinar.
5. Assinatura Apple Developer e provisionamento válidos para iPhone real;
   um `xcodebuild` genérico com `CODE_SIGNING_ALLOWED=NO` não cria IPA
   instalável. Sem credenciais, não prometer link TestFlight.
6. Nunca mesclar PR #9 ou publicar automaticamente sem gates cumpridos.

## Evidência e diagnóstico
- Marcar PASSA / FALHA / NÃO EXECUTADO e anexar log/anotações por ID.
- Para BLE/Noise, capturar metadados mínimos **sem chaves nem plaintext**.
- Caso um teste falhe, corrigir somente na branch da V8 e reexecutar
  até validar. Nenhum pagamento, rede online ou merge como atalho.
