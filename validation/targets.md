# Validation Target URLs

Browser-first target inventory for no-login public validation.

## Primary targets

| Source family | URL | Use | Caveats |
|---|---|---|---|
| Tensor Trust | https://www.tensortrust.ai/ | Browser snapshot, browser vision, source discovery | Public landing page; full game may require account/login. |
| Tensor Trust | https://github.com/HumanCompatibleAI/tensor-trust | Browser snapshot, web_extract parity, repo documentation | GitHub page is stable but technical. |
| PromptInject | https://github.com/agencyenterprise/PromptInject | Browser snapshot, web_extract parity, canonical goal-hijack/prompt-leak reference | Older/small repo; still canonical. |
| garak | https://github.com/NVIDIA/garak | Browser snapshot, source/reference documentation | Broad scanner; filter to prompt-injection/encoding examples only. |
| garak docs | https://docs.garak.ai/ | Browser snapshot, docs/media extraction | Docs structure may change. |
| Promptfoo indirect web pwn | https://www.promptfoo.dev/docs/red-team/strategies/indirect-web-pwn/ | Browser snapshot, web_extract parity, indirect-injection flow | Use this instead of the older 404 indirect-prompt-injection URL. |
| Promptfoo blog | https://www.promptfoo.dev/blog/indirect-prompt-injection-web-agents/ | Browser snapshot, browser vision, indirect web-agent examples | Blog page may be less stable than docs. |
| OWASP GenAI Top 10 | https://genai.owasp.org/llm-top-10/ | Taxonomy/rationale, browser snapshot, web_extract parity | Current archive/index page may evolve. |
| OWASP Foundation project | https://owasp.org/www-project-top-10-for-large-language-model-applications/ | Stable project pointer and taxonomy | Less direct than genai.owasp.org current Top 10 page. |

## Image/media targets

| Source family | URL | Use | Caveats |
|---|---|---|---|
| Public image docs | https://platform.openai.com/docs/guides/images | browser_get_images, browser_vision, image-source discovery | Docs may change. |
| Public NGA image | https://api.nga.gov/iiif/a2e6da57-3cd1-4235-b20e-95dcaefed6c8/full/!800,800/0/default.jpg | vision_analyze public image smoke | External image endpoint may change independently. |

## Notes

- Research discovery should prefer Chrome/browser navigation.
- Avoid paid search/API calls unless explicitly authorized.
- `web_search` rows remain backend validation rows, not primary discovery rows.
