# Pipedream Scraping Setup

Dokumen ini berisi setup penuh workflow scraping PromoHunter di Pipedream,
sebagai pengganti flow scraping n8n yang sebelumnya dipakai.

Fokus dokumen ini adalah fase 1:

1. menerima request dari Flutter admin
2. memilih source aman
3. mengambil HTML
4. membersihkan HTML jadi input AI
5. mengekstrak promo dengan provider OpenAI-compatible
6. mengembalikan response JSON ke caller

Catatan:

- payment tidak dibahas di sini
- upload image ke Supabase Storage belum masuk fase 1
- jalur AI di dokumen ini dibuat aman untuk provider pihak ketiga seperti
  Bluesminds

## Endpoint Workflow

Webhook Pipedream fase 1 yang sedang aktif:

```text
https://eonr7obmd70bcx2.m.pipedream.net
```

## Urutan Step

Urutan step yang disarankan:

1. `trigger`
2. `route_import_source`
3. `select_safe_source`
4. `fetch_html`
5. `prepare_ai_input`
6. `extract_promo_with_ai`
7. `return_response`

## 1. Trigger

Gunakan HTTP / Webhook trigger di Pipedream.

Method:

```text
POST
```

Contoh payload test:

```json
{
  "import_source": "web_scrape",
  "preferred_source": "alfamart",
  "target_sources": ["alfamart"],
  "store_name": "Alfamart",
  "search_query": "promo minyak goreng alfamart bulan ini",
  "period": {
    "month": ""
  }
}
```

## 2. route_import_source

Nama step:

```text
route_import_source
```

Code:

```js
export default defineComponent({
  name: "Parse Import Source",
  description: "Normalize incoming import source request",
  type: "action",
  async run({ steps, $ }) {
    const body = steps.trigger.event.body ?? {};
    const importSource = String(body.import_source ?? "web_scrape").toLowerCase();

    const result = {
      body,
      import_source: importSource,
      is_notion: importSource === "notion",
    };

    $.export("$summary", `Import source: ${importSource}`);
    return result;
  },
});
```

## 3. select_safe_source

Nama step:

```text
select_safe_source
```

Input mapping:

- `preferred_source` -> `steps.route_import_source.$return_value.body.preferred_source`
- `store_name` -> `steps.route_import_source.$return_value.body.store_name`
- `target_sources` -> `steps.route_import_source.$return_value.body.target_sources`
- `search_query` -> `steps.route_import_source.$return_value.body.search_query`
- `period_month` -> `steps.route_import_source.$return_value.body.period.month`

Code:

```js
export default defineComponent({
  name: "Select Safe Promo Source",
  description: "Select a safe promo source from a predefined list based on request parameters",
  type: "action",
  props: {
    preferred_source: {
      type: "string",
      label: "Preferred Source",
      optional: true,
    },
    store_name: {
      type: "string",
      label: "Store Name",
      optional: true,
    },
    target_sources: {
      type: "string[]",
      label: "Target Sources",
      optional: true,
    },
    search_query: {
      type: "string",
      label: "Search Query",
      optional: true,
    },
    period_month: {
      type: "string",
      label: "Period Month",
      optional: true,
    },
  },
  async run({ $ }) {
    const safeSources = [
      {
        name: "Alfamart",
        url: "https://www.suara.com/lifestyle/2026/03/13/160816/promo-minyak-goreng-di-alfamart-diskon-gede-gedean-cek-daftar-lengkap-merek-favorit?page=all",
      },
      {
        name: "Indomaret",
        url: "https://disway.id/read/952156/promo-indomaret-minggu-ini-15-21-juni-2026-spesial-festival-hijriah-diskon-sarden-botan-asahi-cuma-rp10-ribu",
      },
      {
        name: "Super Indo",
        url: "https://www.suara.com/lifestyle/2026/03/29/131130/promo-kebutuhan-dapur-akhir-bulan-di-superindo-minyak-goreng-beras-hingga-daging-ayam?page=1",
      },
      {
        name: "Hero",
        url: "https://katalogpromosi.com/promo-jsm-hero-supermarket-minggu-ini/",
      },
    ];

    let selectedSource = null;
    let discoveryReason = "";

    if (this.preferred_source) {
      selectedSource = safeSources.find(
        (source) => source.name.toLowerCase() === this.preferred_source.toLowerCase()
      );
      if (selectedSource) {
        discoveryReason = "Matched preferred source";
      }
    }

    if (!selectedSource && this.store_name) {
      selectedSource = safeSources.find(
        (source) => source.name.toLowerCase() === this.store_name.toLowerCase()
      );
      if (selectedSource) {
        discoveryReason = "Matched store name";
      }
    }

    if (!selectedSource && this.target_sources?.length) {
      for (const targetSource of this.target_sources) {
        selectedSource = safeSources.find(
          (source) => source.name.toLowerCase() === String(targetSource).toLowerCase()
        );
        if (selectedSource) {
          discoveryReason = "Matched target sources";
          break;
        }
      }
    }

    if (!selectedSource) {
      selectedSource = safeSources[0];
      discoveryReason = "Default source (no match found)";
    }

    const now = new Date();

    const targetPeriodText =
      this.period_month ||
      now.toLocaleString("id-ID", {
        month: "long",
        year: "numeric",
      });

    const targetPeriodKey =
      now.getFullYear() + "-" + String(now.getMonth() + 1).padStart(2, "0");

    const result = {
      source_url: selectedSource.url,
      source_name: selectedSource.name,
      discovery_reason: discoveryReason,
      search_query_used: this.search_query || "",
      target_period_text: targetPeriodText,
      target_period_key: targetPeriodKey,
    };

    $.export("$summary", `Selected source: ${selectedSource.name} (${discoveryReason})`);
    return result;
  },
});
```

## 4. fetch_html

Nama step:

```text
fetch_html
```

Input mapping:

- `source_url` -> `steps.select_safe_source.$return_value.source_url`
- `source_name` -> `steps.select_safe_source.$return_value.source_name`
- `target_period_text` -> `steps.select_safe_source.$return_value.target_period_text`

Code:

```js
import { axios } from "@pipedream/platform";

export default defineComponent({
  name: "Fetch HTML Content",
  description: "Fetches HTML content from a promo source URL with browser-like headers and redirect handling",
  type: "action",
  props: {
    source_url: {
      type: "string",
      label: "Source URL",
    },
    source_name: {
      type: "string",
      label: "Source Name",
      optional: true,
    },
    target_period_text: {
      type: "string",
      label: "Target Period Text",
      optional: true,
    },
  },
  async run({ $ }) {
    const html = await axios($, {
      url: this.source_url,
      method: "GET",
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
      maxRedirects: 5,
      timeout: 30000,
    });

    const result = {
      source_url: this.source_url,
      source_name: this.source_name || "",
      target_period_text: this.target_period_text || "",
      html,
    };

    $.export("$summary", `Successfully fetched HTML content from ${this.source_url}`);
    return result;
  },
});
```

## 5. prepare_ai_input

Nama step:

```text
prepare_ai_input
```

Input mapping:

- `html` -> `steps.fetch_html.$return_value.html`
- `source_name` -> `steps.fetch_html.$return_value.source_name`
- `source_url` -> `steps.fetch_html.$return_value.source_url`
- `target_period_text` -> `steps.fetch_html.$return_value.target_period_text`

Code:

```js
export default defineComponent({
  name: "Prepare AI Input",
  description: "Clean HTML into smaller text for AI extraction",
  type: "action",
  props: {
    html: {
      type: "string",
      label: "HTML",
    },
    source_name: {
      type: "string",
      label: "Source Name",
      optional: true,
    },
    source_url: {
      type: "string",
      label: "Source URL",
      optional: true,
    },
    target_period_text: {
      type: "string",
      label: "Target Period Text",
      optional: true,
    },
  },
  async run({ $ }) {
    const rawHtml = String(this.html || "");

    const cleaned = rawHtml
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
      .replace(/<svg[\s\S]*?<\/svg>/gi, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/&nbsp;/gi, " ")
      .replace(/&amp;/gi, "&")
      .replace(/&quot;/gi, '"')
      .replace(/&#39;/gi, "'")
      .replace(/\s+/g, " ")
      .trim();

    const aiText = cleaned.slice(0, 12000);

    $.export("$summary", `Prepared AI input (${aiText.length} chars)`);

    return {
      source_name: this.source_name || "",
      source_url: this.source_url || "",
      target_period_text: this.target_period_text || "",
      ai_text: aiText,
    };
  },
});
```

## 6. extract_promo_with_ai

Nama step:

```text
extract_promo_with_ai
```

Input mapping:

- `ai_text` -> `steps.prepare_ai_input.$return_value.ai_text`
- `source_name` -> `steps.prepare_ai_input.$return_value.source_name`
- `source_url` -> `steps.prepare_ai_input.$return_value.source_url`
- `target_period_text` -> `steps.prepare_ai_input.$return_value.target_period_text`
- `openai_api_key` -> secret API key provider
- `base_url` -> default `https://api.bluesminds.com/v1`
- `model` -> default `gpt-5-mini`

Code:

```js
import OpenAI from "openai";

export default defineComponent({
  name: "Extract Promo Data with OpenAI-Compatible API",
  description: "Use an OpenAI-compatible provider to extract multiple promo items from cleaned page text",
  type: "action",
  props: {
    ai_text: {
      type: "string",
      label: "AI Text",
    },
    source_name: {
      type: "string",
      label: "Source Name",
      optional: true,
    },
    source_url: {
      type: "string",
      label: "Source URL",
      optional: true,
    },
    target_period_text: {
      type: "string",
      label: "Target Period Text",
      optional: true,
    },
    openai_api_key: {
      type: "string",
      label: "API Key",
      secret: true,
    },
    base_url: {
      type: "string",
      label: "Base URL",
      default: "https://api.bluesminds.com/v1",
    },
    model: {
      type: "string",
      label: "Model",
      default: "gpt-5-mini",
    },
  },

  async run({ $ }) {
    const client = new OpenAI({
      apiKey: this.openai_api_key,
      baseURL: this.base_url,
    });

    const aiText = String(this.ai_text || "").slice(0, 12000);
    const sourceName = this.source_name || "Promo Online";
    const sourceUrl = this.source_url || "";
    const targetPeriodText = this.target_period_text || "";

    const prompt =
      "Extract as many real promo variants as possible from this page text. " +
      "Return JSON only, with no markdown fences and no explanation.\n\n" +
      "Required output schema:\n" +
      JSON.stringify({
        source_name: "string",
        message: "string",
        promotions: [
          {
            product_name: "string",
            brand: "string",
            image_url: "string",
            original_image_url: "string",
            normal_price: null,
            promo_price: null,
            unit_size: 1,
            unit_type: "pcs",
            store_name: "string",
            store_address: "Sumber promo online",
            category_name: "string",
            start_date: "",
            end_date: "",
            terms: "string",
            source_url: "string"
          }
        ]
      }, null, 2) +
      "\n\nRules:\n" +
      "- Find as many valid promo items as possible\n" +
      "- Avoid duplicates\n" +
      "- Prefer visible rupiah prices\n" +
      "- Use categories like Minyak, Beras, Susu, Deterjen, Grocery, Promo Online\n" +
      "- If store address is unknown, use 'Sumber promo online'\n" +
      "- If unit is unknown, use unit_size 1 and unit_type 'pcs'\n" +
      "- Dates should be yyyy-MM-dd when known, else empty string\n" +
      "- source_url must always equal the provided source URL\n" +
      "- Always return at least 1 promotion item if the page clearly discusses promos\n" +
      "- Never return an empty promotions array unless the page is clearly unrelated to promotions\n\n" +
      `Source Name: ${sourceName}\n` +
      `Source URL: ${sourceUrl}\n` +
      `Target Period: ${targetPeriodText}\n\n` +
      `TEXT:\n${aiText}`;

    let parsed;

    try {
      const response = await client.chat.completions.create({
        model: this.model,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content:
              "You extract PromoHunter promotion data from cleaned page text and return JSON only.",
          },
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      let content = response.choices?.[0]?.message?.content || "{}";

      if (Array.isArray(content)) {
        content = content.map((item) => item?.text || item?.content || "").join("\n");
      }

      content = String(content).trim();

      if (content.startsWith("```")) {
        content = content
          .replace(/^```json/i, "")
          .replace(/^```/i, "")
          .replace(/```$/i, "")
          .trim();
      }

      try {
        parsed = JSON.parse(content);
      } catch (error) {
        const match = content.match(/\{[\s\S]*\}$/);
        if (!match) {
          throw new Error(`Provider did not return valid JSON: ${content.slice(0, 1000)}`);
        }
        parsed = JSON.parse(match[0]);
      }
    } catch (error) {
      $.export("$summary", `AI extraction failed: ${error.message}`);

      parsed = {
        source_name: sourceName,
        message: "AI extraction failed, returning fallback promo",
        promotions: [],
      };
    }

    const finalPromotions = (parsed.promotions || [])
      .map((promo) => ({
        product_name: promo.product_name || "",
        brand: promo.brand || sourceName,
        image_url: promo.image_url || promo.original_image_url || "",
        original_image_url: promo.original_image_url || promo.image_url || "",
        normal_price: promo.normal_price ?? null,
        promo_price: promo.promo_price ?? null,
        unit_size: promo.unit_size ?? 1,
        unit_type: promo.unit_type || "pcs",
        store_name: promo.store_name || sourceName,
        store_address: promo.store_address || "Sumber promo online",
        category_name: promo.category_name || "Promo Online",
        start_date: promo.start_date || "",
        end_date: promo.end_date || "",
        terms: promo.terms || "",
        source_url: sourceUrl,
      }))
      .filter((promo) => promo.product_name);

    const deduped = [];
    const seen = new Set();

    for (const promo of finalPromotions) {
      const key = `${promo.product_name.toLowerCase()}::${promo.promo_price ?? ""}`;
      if (seen.has(key)) continue;
      seen.add(key);
      deduped.push(promo);
    }

    let finalList = deduped;

    if (finalList.length === 0) {
      finalList = [
        {
          product_name: sourceName || "Promo Online",
          brand: sourceName || "Promo Online",
          image_url: "",
          original_image_url: "",
          normal_price: null,
          promo_price: null,
          unit_size: 1,
          unit_type: "pcs",
          store_name: sourceName || "Promo Online",
          store_address: "Sumber promo online",
          category_name: "Promo Online",
          start_date: "",
          end_date: "",
          terms: targetPeriodText
            ? `Promo terdeteksi untuk periode ${targetPeriodText}.`
            : "Promo dari sumber publik.",
          source_url: sourceUrl,
        },
      ];
    }

    const result = {
      direct_insert: false,
      inserted_to_supabase: false,
      source_name: parsed.source_name || sourceName,
      message: parsed.message || `Extracted ${finalList.length} promotion(s) with compatible AI provider`,
      promotions: finalList,
    };

    $.export("$summary", `AI extracted ${finalList.length} promotion(s)`);
    return result;
  },
});
```

## 7. return_response

Nama step:

```text
return_response
```

Tujuan:

- mengembalikan output final step AI ke caller

Body response harus mengambil:

```text
steps.extract_promo_with_ai.$return_value
```

Jika pakai code step sederhana:

```js
export default defineComponent({
  name: "Return HTTP Response",
  type: "action",
  async run({ steps, $ }) {
    return steps.extract_promo_with_ai.$return_value;
  },
});
```

## Hasil Minimum yang Dianggap Benar

Workflow fase 1 dianggap berhasil bila webhook mengembalikan JSON seperti:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false,
  "source_name": "Alfamart",
  "message": "Extracted 1 promotion(s) with compatible AI provider",
  "promotions": [
    {
      "product_name": "Promo Minyak Goreng",
      "brand": "Alfamart",
      "image_url": "https://...",
      "original_image_url": "https://...",
      "normal_price": 69900,
      "promo_price": 59900,
      "unit_size": 1,
      "unit_type": "pcs",
      "store_name": "Alfamart",
      "store_address": "Sumber promo online",
      "category_name": "Minyak",
      "start_date": "",
      "end_date": "",
      "terms": "Promo terdeteksi untuk periode Juni 2026.",
      "source_url": "https://..."
    }
  ]
}
```

## Catatan Penting

1. Provider pihak ketiga bisa timeout jika input terlalu besar.
   Karena itu `prepare_ai_input` wajib dipakai.

2. Jangan map input sebagai teks literal seperti:

```text
steps.prepare_ai_input.$return_value.ai_text
```

Gunakan data picker atau expression dinamis yang benar.

3. Jika provider tetap tidak bisa mengembalikan promo, step AI saat ini tetap
   mengembalikan fallback minimal 1 item.

4. Fase 2 berikutnya adalah upload gambar ke Supabase Storage dan mengganti
   `image_url` dari URL eksternal menjadi URL public Storage.
