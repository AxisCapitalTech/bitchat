# MeshPriv — interface Matrix e Axis Pay sandbox nativo

## Escopo
Esta branch unifica Conversas / Mesh / Carteira no mesmo aplicativo iOS.
Não altera Noise, packet format, UUIDs BLE, retransmissão ou criptografia.
Não comprova ausência de internet no binário: Nostr/Tor ainda estão em módulos
não removidos completamente das branches anteriores.

### Conversas
A ContentView original continua como chatContent, com sheets privadas, QR de
identidade, panic wipe, mídia e compositor do upstream. A navegação nova
envolve a tela existente, sem substituir suas funções criptográficas.

### Mesh
Usa PeerListModel.meshRows para listar peers conectados ou alcançáveis via BLE.
Tocar no peer retorna às conversas e abre DM com startConversation(with:).
Não implementa varredura nova, nem altera o rádio.

### Carteira
É exclusivamente um simulador integrado ao app; não abre a antiga demo web.
Cria cobranças locais em BRL com marcador de token USDC ou USDT. O QR usa CoreImage
do iOS e contém um identificador de DEMO, deliberadamente não pagável:
  meshpriv-demo://charge/<uuid>?brl=50.00&asset=USDC
O app não se conecta a blockchain, não converte valores nem movimenta tokens.
O botão 'Simular pagamento' altera SOMENTE estado local, sem comprovante real.
Dados do sandbox são armazenados no UserDefaults (não incluem dados reais).
O panic wipe do ChatViewModel agora apaga a chave de histórico de sandbox.

### Visual
Estética cyberpunk Matrix original: fundo preto profundo, verde neon, fonte
monoespaçada nos destaques. Labels principais em PT-BR e inglês conforme locale.
Sem uso de imagens, trilhas sonoras ou elementos protegidos do filme.

## Testes obrigatórios
1. Compilar iOS simulator com Xcode e rodar testes upstream (Noise/mesh).
2. Alternar entre abas sem perder rascunho nem bloquear o compositor.
3. A->B e A->B->C com rádio BLE e Wi-Fi/dados desligados.
4. Abas Mesh: abrir DM pelo peer direto/relay e confirmar fingerprints.
5. Carteira: gerar QR, confirmar prefixo demo, simular, reabrir, persistir.
6. Panic wipe: confirmar que o histórico demo também desaparece.
7. Testar valores inválidos, decimal pt-BR, acessibilidade e contraste.
8. Auditar rede do binário em dispositivo e evitar bloqueios do BLE em background.

## Limites para produção
Nenhum pagamento real, onboarding, custódia, cartões, câmbio ou dados fiscais.
Produção exige autenticação, autorização por loja, cotação rastreável, validação
blockchain independente (network/mint/destino/valor/expiração/finalização),
reconciliação idempotente e revisão jurídica/tributária LGPD/BCB.
Uma versão de app com pagamentos online exigirá a respectiva permissão de rede:
o projeto deixa de ser 'nenhum código de internet em todo o app',
mas os transportes de MENSAGENS permanecem exclusivamente BLE.

## Estado
Sem merge, sem publicação em lojas; CI e testes físicos pendentes nesta branch.