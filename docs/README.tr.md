<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · **🇹🇷 Türkçe** · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

**Claude**, **Codex** ve **Cursor** limitlerinizin ne kadarını kullandığınızı gösteren hafif bir macOS menü çubuğu uygulaması — ayrıca token istatistikleri ve aynı kullanımın açık API'ler üzerinden ne kadara mal olacağı.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Özellikler

- **Limitler bir bakışta** — Claude ve Codex için 5 saatlik ve haftalık pencereler, Cursor için plana dahil kullanım havuzları; her biri ilerleme çubuğu, sıfırlanmaya kalan süre ve tam sıfırlanma tarihiyle.
- **Model bazlı haftalık limitler** Claude için (Opus, Sonnet, Fable, …), API bildirdiği anda.
- **Kullanım istatistikleri** — türe göre token, maliyet, model ve proje bazlı dağılım, günlük grafik; Bugün / 7 gün / 30 gün / Tümü.
- **Bildirimler** bir limit eşiği aştığında; genel varsayılan ve limit başına kurallar (sessize alma, özel eşik).
- **İsteğe bağlı otomatik yenileme**, oturum açılınca başlatma, 17 arayüz dili.
- **Havadan güncelleme** GitHub Releases üzerinden, SHA-256 ile doğrulanmış.
- **Hesap yok, telemetri yok.** AgentBar resmi istemcilerin Mac'inizde zaten sakladığı token'ları okur ve yalnızca sağlayıcıların kendi API'leriyle konuşur.

## Gereksinimler

- macOS 14 Sonoma veya üzeri (Apple Silicon ya da Intel).
- Oturum açılmış en az bir istemci: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI veya masaüstü uygulaması), [Cursor](https://cursor.com). Kullanmadığınız sağlayıcılar Ayarlar'dan gizlenebilir.

## Kurulum

1. [Son sürümden](https://github.com/funbool/agentbar/releases/latest) `AgentBar.zip` dosyasını indirin.
2. Açın ve `AgentBar.app` dosyasını `/Applications` klasörüne taşıyın.
3. Uygulamayı açın. Kendini oturum açma öğesi olarak kaydeder (Ayarlar'dan kapatılabilir).

**Gatekeeper.** Sürümler ad hoc imzalıdır, noter onaylı değildir. macOS yeni indirilen kopyayı açmayı reddederse, uygulamaya sağ tıklayıp bir kez *Aç*'ı seçin ya da karantina bayrağını kaldırın:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Anahtar Zinciri sorusu.** İlk Claude yenilemesinde macOS, `security`'nin *Claude Code-credentials* öğesini okuyup okuyamayacağını sorar. **Her Zaman İzin Ver**'i seçin. Claude Code token'ını yeniledikten sonra soru tekrar çıkabilir — bu beklenen bir durumdur.

Ayrıca [kaynaktan derleyebilirsiniz](#kaynaktan-derleme).

## Nasıl çalışır

AgentBar asla oturum açmanızı istemez. Her istemcinin Mac'inizde zaten tuttuğu kimlik bilgilerini okur ve istemcilerin kullandığı uç noktaları çağırır.

| Sağlayıcı | Kimlik bilgileri | Uç nokta | Gösterilen |
|---|---|---|---|
| Claude | Anahtar Zinciri öğesi `Claude Code-credentials` (`/usr/bin/security` ile okunur) | `api.anthropic.com/api/oauth/usage` | 5 saatlik pencere, haftalık pencere, model bazlı haftalık limitler |
| Codex | `~/.codex/auth.json` (veya `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | 5 saatlik pencere, haftalık pencere, plan |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (salt okunur) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Cursor modelleri havuzu (Auto / Composer / Grok), API modelleri havuzu, isteğe bağlı harcama, haftalık Grok Bot, dönem harcaması |

AgentBar token yenilemez. Bir sağlayıcı *oturum süresi doldu* gösteriyorsa o istemciyi bir kez açın — token'ı yeniler ve AgentBar bir sonraki yenilemede alır.

## Panel

- Menü çubuğu simgesine tıklayın: tüm sağlayıcılar hemen yenilenir; yüklenirken önceki değerler gösterilir.
- Çubuklar %60'ın altında yeşil, üstünde sarı, bildirim eşiğine ulaşınca kırmızıdır.
- Her limit kalan süreyi ve tam sıfırlanma anını gösterir, örn. *2s 15d sonra sıfırlanır · Per 24 Eyl 20:00*.
- Bir limitin yanındaki zil, o limit için bildirimlerin açık olduğunu gösterir (Ayarlar'dan yapılandırılır).
- Alt çubuk: istatistikler · yenile · ayarlar · çık.

## Kullanım istatistikleri

Alt çubuktaki grafik düğmesi istatistik penceresini açar. Üstte sağlayıcı ve dönemi değiştirin; grafiğin üzerine gelince günün toplamını ya da tek bir modelin payını görürsünüz.

| Sağlayıcı | Kaynak | Maliyet |
|---|---|---|
| Claude | Claude Code transkriptleri (`~/.claude/projects/**/*.jsonl`), bir kez dizinlenir ve dosya bazında önbelleklenir | Aynı kullanımın API üzerinden maliyeti: girdi/çıktı liste fiyatı, önbellek yazma ×1,25 (5 dk TTL) / ×2 (1 sa TTL), önbellek okuma ×0,1 |
| Codex | Oturum kayıtları (`~/.codex/sessions/**/*.jsonl`) | OpenAI API liste fiyatları; önbellekli girdi ×0,1. Açık fiyatı olmayan modellerde yalnızca token gösterilir |
| Cursor | Cursor panosundaki kullanım olayları, yerelde önbelleklenir. İlk açılışta tüm geçmişi mi yoksa yalnızca geçerli faturalama dönemini mi yükleyeceğinizi seçersiniz; sonraki yenilemeler yalnızca yeni olayları getirir | Cursor'un her istek için bildirdiği şekilde |

**AgentBar'ın Claude toplamları neden Claude Code'daki `/stats` ile farklı?** Claude Code her transkript satırını sayar; birden çok bloktan (düşünme, metin, araç çağrıları) oluşan bir yanıt aynı kullanım kaydını paylaşan birkaç satır olarak yazılır ve birden çok kez sayılır. AgentBar her yanıtı son kullanım değerleriyle bir kez sayar — API'nin gerçekten faturaladığı budur — ve karşılaştırma için Claude Code rakamını yanında gösterir.

700 MB transkripti dizinlemek ilk seferde yaklaşık 10 saniye, sonrasında bir saniyeden çok daha az sürer. Önbellekler `~/Library/Application Support/AgentBar/` içindedir.

## Bildirimler

- Ayarlar → Bildirimler'den bildirimleri açın ve varsayılan eşiği seçin (%50–95).
- Her limit Ayarlar → Bildirimler'den sessize alınabilir ya da kendi eşiğini alabilir.
- Her limit için sıfırlanma döngüsü başına bir bildirim alırsınız.
- Limitler her yenilemede denetlenir: otomatik yenileme açıksa zamanlamaya göre, değilse yalnızca panel açıldığında.

## Ayarlar

- **Genel** — yenileme aralığı (kapalı / 1 / 5 / 15 / 30 / 60 dk), görünür sağlayıcılar, dil, oturum açılınca başlatma, güncellemeler.
- **Bildirimler** — ana anahtar, varsayılan eşik, limit başına kurallar.

## Güncellemeler

AgentBar GitHub Releases'i günde bir kez ve *Güncellemeleri denetle*'ye her bastığınızda kontrol eder. Daha yeni bir sürüm varsa panelde *Güncelle* düğmesi belirir. Güncelleme indirilir, SHA-256'sı yayımlanan toplamla doğrulanır, paket kimliği ve sürüm kontrol edilir, eski uygulama Çöp Sepeti'ne taşınır ve yenisi başlatılır. Herhangi bir sürümü [sürümler sayfasından](https://github.com/funbool/agentbar/releases) elle de kurabilirsiniz.

## Kaynaktan derleme

Xcode 15 veya üzeri gerekir (Swift 5.9). Üçüncü taraf bağımlılık yoktur.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # birim testleri
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # derle, /Applications'a kopyala ve başlat
```

Hata ayıklama yardımcıları (paketin içindeki ikiliyi ya da `.build/debug/AgentBar`'ı çalıştırın):

```bash
AgentBar --dump            # her sağlayıcıyı bir kez sorgula ve ayrıştırılmış limitleri yazdır
AgentBar --raw             # her uç noktanın ham JSON'unu yazdır
AgentBar --stats           # yerel Claude/Codex günlüklerini dizinle ve toplamları yazdır
AgentBar --cursor-events   # Cursor kullanım olaylarını getir ve toplamları yazdır
AgentBar --update          # tam güncelleme döngüsünü arayüzsüz çalıştır
```

### Sürüm yayımlama

```bash
./scripts/release.sh 0.2.0
```

Bu, `Packaging/Info.plist` içindeki sürümü yükseltir, `v0.2.0` etiketini oluşturur ve gönderir. GitHub Actions testleri çalıştırır, uygulamayı derler, `AgentBar.zip` ve `AgentBar.zip.sha256` dosyalarını sürüm olarak yayımlar; çalışan kopyalar bir sonraki denetimde bunu alır.

## Gizlilik ve güvenlik

- **Okur:** Claude Code Anahtar Zinciri öğesi, `~/.codex/auth.json`, Cursor'un `state.vscdb` dosyası (salt okunur), yerel transkriptler ve oturum günlükleri.
- **Yazar:** `~/Library/Application Support/AgentBar/` altına tercihler ve önbellekler.
- **Ağ:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (kendi kullanım verileriniz) ve `api.github.com` / `github.com` (güncelleme denetimi ve indirme). Başka hiçbir şey.
- Sürümler GitHub Actions tarafından etiketli kaynaktan derlenir; iş akışı `.github/workflows/release.yml` içindedir.

## Sorun giderme

| Belirti | Ne yapmalı |
|---|---|
| *Oturum açılmamış — … uygulamasını açın* | O istemcide bir kez oturum açın; AgentBar kayıtlı token'ı bir sonraki yenilemede okur. |
| Anahtar Zinciri sorusu sürekli çıkıyor | *Her Zaman İzin Ver*'i seçin. Bir süre sonra yeni bir soru, Claude Code'un token'ını yenilediği anlamına gelir. |
| Cursor hiçbir şey göstermiyor | Oturum token'ını yenilemesi için Cursor'u bir kez açın, sonra AgentBar'ı yenileyin. |
| Uygulama indirdikten sonra açılmıyor | Gatekeeper — bkz. [Kurulum](#kurulum). |
| İstatistikler *Dizinleniyor…* durumunda kalıyor | Büyük transkript klasörlerinin ilk dizinlenmesi zaman alır; sonraki çalıştırmalar önbelleği kullanır. |

## Teşekkür

Uç nokta araştırmasında açık kaynaklı [CodexBar](https://github.com/steipete/CodexBar) projesinden yararlanıldı.

## Lisans

[MIT](../LICENSE)
