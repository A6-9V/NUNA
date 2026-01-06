# MQL5 Workspace

MQL5 Algo Forge / [LengKundee](https://www.mql5.com/en/users/LengKundee)

## Paths
- Terminal data: `C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5`
- Experts: `MQL5\Experts\Advisors`
- Profiles: `MQL5\Profiles` (charts/templates)
- Logs: `MQL5\Logs`

## Active EAs (enhanced)
- `ExpertMACD_Enhanced.mq5`
- `ExpertMAMA_Enhanced.mq5`
- `ExpertMAPSAR_Enhanced.mq5`

## Maintenance
- Profiles fix: copy defaults into `Profiles\Charts\<profile>` if missing/empty.
- Compile EAs in MetaEditor (F7) after updates.
- Keep API/credentials out of this tree (store in Credential Manager).

## Git (Forge)
- Upstream: `https://forge.mql5.io/LengKundee/mql5.git`
- Use token via env var when pulling/pushing; do not store tokens in files.