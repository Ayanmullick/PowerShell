$head = @'
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
  /* remove UA chrome that causes the white border & ensure no fallback bg peeks through */
  html,body{margin:0;padding:0;background:transparent}
  /* responsive wrapper + table layout tweaks */
  .scrollbox{overflow:auto;max-width:100%}
  fluent-data-grid{display:inline-block}
  fluent-data-grid-cell{white-space:nowrap}
  fluent-data-grid-row > fluent-data-grid-cell:not(:first-child){
    text-align:right; font-variant-numeric:tabular-nums;
  }
</style>
<script type="module" src="https://unpkg.com/@fluentui/web-components"></script>
<script type="module">
  // Build a Fluent Data Grid from the ConvertTo-Html table (once)
  addEventListener("DOMContentLoaded", () => {
    const t = document.querySelector("table"); if (!t) return;

    // ConvertTo-Html puts headers in the first row
    const trs = [...t.querySelectorAll("tr")];
    const headers = [...trs.shift().querySelectorAll("th")].map(th => th.textContent.trim());
    const rows = trs.map(tr => {
      const cells = [...tr.querySelectorAll("td")];
      return Object.fromEntries(headers.map((h,i)=>[h,(cells[i]?.textContent.trim()) ?? ""]));
    });

    const grid = document.createElement("fluent-data-grid");
    grid.generateHeader = "sticky";
    grid.rowsData = rows; // DataGrid API

    const wrap = document.createElement("div"); wrap.className = "scrollbox";
    t.replaceWith(wrap); wrap.appendChild(grid);
  });

  // 🌓 icon-only theme toggle (scoped to provider luminance)
  addEventListener("click", e=>{
    if(!e.target.closest("[data-toggle-theme]")) return;
    const p = document.getElementById("fluent-root");
    const cur = p.getAttribute("base-layer-luminance") ?? "1";
    p.setAttribute("base-layer-luminance", cur === "1" ? "0.15" : "1"); // light ↔ dark
  });
</script>
'@

# Provider now covers the entire viewport to eliminate the top sliver
$pre  = @"
<fluent-design-system-provider id="fluent-root" base-layer-luminance="1"
  style="position:fixed; inset:0; overflow:auto; display:block">
  <div style="display:flex;justify-content:end;margin:.5rem 0">
    <button data-toggle-theme title="Toggle theme" aria-label="Toggle theme">🌓</button>
  </div>
  <h1>Processes</h1><p>Updated $stamp</p>
"@
$post = "</fluent-design-system-provider>"

# Generate the page (ConvertTo-Html stays LAST)
Get-Process |
  Sort-Object WorkingSet64 -Descending |
  Select-Object -First 20 ProcessName, Id, CPU,
    @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,2)}} |
  ConvertTo-Html -As Table -Title 'Processes' -Head $head -PreContent $pre -PostContent $post |
  Set-Content fluentprocesses.html -Encoding utf8