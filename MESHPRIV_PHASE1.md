# MeshPriv — Fase 1 (rebrand isolado do fork iOS)

Este fork usa o código público do [permissionlesstech/bitchat](https://github.com/permissionlesstech/bitchat), preservando o histórico Git e os avisos de licença. `LICENSE` original: Unlicense. Conferir também as licenças das dependências antes de distribuir.

## Estado

- Branch de trabalho: `phase1/meshpriv-rebrand`.
- Commit-base `main`: `04995f68e470a18d1fc99f86fa326c2a87bab4f2`.
- Nome comercial em configurações iOS/macOS: **MeshPriv**.
- Identificador provisório de distribuição: `app.meshpriv.mobile`; App Group: `group.app.meshpriv.mobile`.
- `DEVELOPMENT_TEAM` do upstream foi desativado; configurar equipe e provisionamento próprios antes de instalar em dispositivo.
- Motor BLE, Noise, protocolo binário, UUIDs de rádio e QR de verificação **não foram modificados**.
- **Ainda não é offline-only:** Nostr, Tor, geohash e comunicação online seguem intactos até a Fase 2.
- Nome do módulo, símbolos, algumas strings de interface e arquivos de ícones continuam relacionados ao upstream. Rebrand visual completo ainda pendente. **Não distribuir como MeshPriv completo.**

## Arquivos modificados até agora

- `Configs/Release.xcconfig`: Bundle ID, App Group, Team ID provisório.
- `Configs/Local.xcconfig.example`: exemplos com novos IDs.
- `bitchat.xcodeproj/project.pbxproj`: nome visível do app e da extensão.
- `bitchat/Info.plist`: textos de permissões com nova marca.
- `bitchatShareExtension/Info.plist`: nome exibido da extensão.

## Validar (em macOS com Xcode, não executado neste ambiente)

```bash
xcodebuild -list -project bitchat.xcodeproj
xcodebuild -project bitchat.xcodeproj -scheme bitchat_iOS -configuration Debug \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff main...HEAD --name-only
git diff --check main...HEAD
```

Validar também targets da extensão, localizações PT-BR/EN, QR entre Android e iOS, BLE com dois aparelhos e background antes de concluir Fase 1.

O rebrand não deve alterar o Noise, a criptografia, os identificadores binários do protocolo, nem os UUIDs BLE apenas para trocar nomes comerciais. O esquema de QR possui um contexto assinado e precisa de testes de compatibilidade antes de eventuais mudanças.

## Riscos e pendências

- Compilação Xcode e testes upstream **não executados**.
- Ícones do upstream **ainda presentes nesta branch**; o pacote local de rebrand possui assets próprios a aplicar em seguida.
- A disponibilidade do Bundle ID nas lojas não foi verificada.
- O app ainda contém infraestrutura de internet.
