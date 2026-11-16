# Contribuindo com Dragon Adventure: O Último Herói

Obrigado pelo interesse em contribuir! Abaixo estão as diretrizes essenciais para manter o projeto limpo, seguro e compatível com a exportação Web (WebGL 2.0 / Google Chrome).

## Ambiente Recomendado
- **Engine:** Godot Engine **4.7.2** (Renderer `gl_compatibility`)
- **Navegador alvo:** Google Chrome (para validação WebGL)
- **Sistema:** Windows / PowerShell para utilitários de build e scripts de geração

## Variáveis de Ambiente e Segurança
- **Nunca** faça commit de chaves de API ou arquivos `.env`.
- Copie [`.env.example`](.env.example) para uso local caso precise rodar scripts de geração em [`scripts/`](scripts/):
  - `PIXELLAB_API_KEY`
  - `ELEVENLABS_API_KEY`

## Padrões de Código (GDScript)
- Preserve os comentários e docstrings (`##`) existentes.
- Use helpers centralizados já disponíveis no projeto:
  - [`FloatingText.spawn(...)`](scripts/FloatingText.gd) para números flutuantes em combate/loot;
  - [`GameData.get_map_bounds(...)`](autoload/GameData.gd) para limites de mapa;
  - [`MedievalUI.create_notes_badge(...)`](scripts/MedievalUI.gd) para badges de cédulas na interface.
- Ao alterar estatísticas de monstros, armas, armaduras, mundos ou sistemas, sincronize a documentação em [`docs/`](docs/INDEX.md).

## Checklist Antes do Pull Request
1. Importar e validar sem erros de script:
   ```powershell
   godot --headless --path . --import
   godot --headless --path . --quit-after 3
   ```
2. Exportar o preset `"Web"` e testar no Google Chrome via [`scripts/run_web_chrome.ps1`](scripts/run_web_chrome.ps1):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\run_web_chrome.ps1 -Port 8080
   ```
3. Conferir que o console do navegador e a saída headless do Godot estão sem erros.
