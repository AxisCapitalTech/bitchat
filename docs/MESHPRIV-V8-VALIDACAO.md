# MeshPriv V8 — Validação nativa e auditoria de fidelidade
Data: 29/10/2026 (Brasil)

## Referência visual oficial
A composição aprovada pelo usuário mostra três iPhones: Conversas, Radar Mesh
e Carteira Axis Pay, com marca MeshPriv, preto profundo, verde neon, barra
inferior de quatro itens e acabamento iOS premium.

**Não está comprovado que a V8 seja idêntica à referência.**
O material aprovado é uma composição publicitária em perspectiva, não
screenshots em resolução nativa. Não inferir equivalência de pixels de um
mockup em perspectiva.

### Auditoria real das capturas — 30/10/2026
- Artefato inspecionado: run `40990882082`, `meshpriv-v8-native-screen-png`
  (4 imagens de 786×1560 px renderizadas a 2×).
- Falha CONFIRMADA de geração de capturas: todas as quatro imagens exibiam
  somente cabeçalho Matrix e barra inferior, com o corpo central uniformemente
  preto. Uma verificação de contraste em pixels na região central encontrou
  **0 amostras de contraste nas quatro telas**. Portanto, a suíte anterior
  passou falsamente como validação visual; NÃO declarar paridade com a arte.
- Patch `bc63da43`: trocar `ImageRenderer` isolado pelo
  `UIHostingController` em `UIWindow`, permitir ciclo de atualização
  de layout SwiftUI e adicionar asserção de contraste no corpo central.
- Critério: a próxima execução iOS precisa aprovar a asserção anti-blank
  e exportar conteúdos reais de Conversas, Radar, Carteira e Perfil.
- Se a asserção ainda falhar, corrigir renderização/layout novamente;
  nunca remover o assert ou aceitar screenshots vazios.

### Provas de interface (capturas de simulador)
A suíte `bitchatTests/MeshPrivV8VisualSnapshots.swift` captura **quatro telas**
em 393×780 pt, PT-BR e tema escuro, anexadas ao resultado XCTest e ao artefato
GitHub Actions `meshpriv-v8-ios-visual-review`. Imagens recebem marca
"UI TEST · DEMO" e os dados da lista de conversas são fictícios **apenas no teste**.
A UI de produção usa `PeerListModel.meshRows` e `recentChatRows` reais.

Comparar as capturas dos artefatos com a referência aprovada e registrar,
para cada tela, PASSA/NÃO PASSA para:
- Conversas: densidade da lista, hierarquia de nome/hora/última mensagem,
  busca, filtros, abrir DM, fotos opcionais versus monogramas.
- Radar: círculos, posições esquemáticas, feedback de conexões e lista.
  Não sugerir que posições esquemáticas representam coordenadas reais.
- Carteira: proporção do cartão, ações, seleção USDC/USDT, QR DEMO
  e clareza do estado "sem carteira conectada".
- Perfil e navegação: quatro abas, área segura, contraste e botão de pânico.
- Testar no menor simulador e em iPhone moderno com VoiceOver e Dynamic Type.

### Limites de fidelidade e privacidade
- A referência tem retratos fotográficos. A base BLE atual não inclui fotos
  públicas verificadas; a UI real mostra monogramas. Não inventar foto de
  contato real nem buscar perfis de terceiros. Implementação futura de fotos
  locais exige consentimento/armazenamento seguro e política de metadados.
- A referência contém distâncias em metros, geolocalização e saldo positivo.
  **Não fabricar estes dados na UI de produção.** Radar é esquemático e o
  Axis Pay continua sandbox sem saldo confirmado.
- Canais públicos mesh **não** são E2EE; DMs Noise são.
- A UI web V6 não é prova de BLE real nem do layout SwiftUI nativo.

## Gate funcional
1. Compilar o Release universal iOS/macOS com assinatura desativada.
2. Executar suíte SwiftPM e iOS simulator, SwiftLint, testes de pacote e
   guard de inicialização offline sem resultados inventados.
3. Performance: preservar o piso `pipeline.publicIngest >= 2400 msg/s`.
   Base V7 observada na CI: 1.097 a 1.261, reprovado em 3 medições.
   V8 introduz flush de rajada aos 40 itens com testes de deduplicação
   e roteamento; a CI deve demonstrar melhora real. **Não abaixar o piso.**
4. Fazer teste em 2 aparelhos físicos, depois 3 com relay A→B→C:
   descoberta BLE, tráfego sem Wi-Fi/dados, Noise privado, reconexão,
   guarda offline, duplicatas, background, screenshots e wipe.
5. Auditar egress de IP ao abrir **todas** as telas e extensões.
   Guard estático sozinho não garante app 100% offline.
6. TestFlight requer assinatura/provisionamento e conta apropriada; uma
   compilação genérica no GitHub não produz IPA instalável.

## Periphery — estado da V7 e risco de remoção
A V7 tinha **46 avisos**, incluindo:
- Tor/Nostr/geohash: enum `TorLifecycleEvent`, bridge de identidade,
  `NostrRelayManager`, `GeohashPresenceService`, bridge sweep,
  `ChatViewModel+Nostr`, gerenciador de subscrições, inbound pipeline,
  `Arti/TorManager` e interfaces de gateway.
- Componentes BLE: funções de capability/bridge/routing, Noise static key
  e lista de peer keys. Devem ser protegidos até análise de wire/Noise/
  dispositivos reais; não remover por uma advertência da Periphery.
- Falsos positivos possíveis pela diferença entre scan macOS e recursos
  iOS, referências indiretas e testes.

Triage seguro:
1. Registrar declaração, todas as referências e o caminho de execução real
   em ambas plataformas.
2. Identificar dependências transitivas, símbolos usados por reflexão/objc,
   testes e protocolo binário upstream.
3. Somente excluir legado comprovadamente inalcançável após testes.
4. Preservar precisão dos testes; não excluir arquivos da varredura para
   conseguir resultado "verde" artificial.
5. Reexecutar Periphery, CI e testes em hardware e auditar o diff.
O objetivo é remover **com segurança**, não esconder 46 avisos.

## Restrições desta branch
- Sem merge, push em main, deploy para clientes ou publicação App Store.
- Sem novas rotas de rede em mensagens BLE e sem alterações em Noise/codec.
- Sem liberar pagamentos USDT/USDC ou habilitar custódia de ativos.
- PR #8 (V7 native) é a base da branch V8 e permanece draft.
