<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%
    String result   = (String)  request.getAttribute("result");
    String expr     = (String)  request.getAttribute("expression");
    String error    = (String)  request.getAttribute("error");
    String num1     = (String)  request.getAttribute("num1");
    String num2     = (String)  request.getAttribute("num2");
    String selOp    = (String)  request.getAttribute("operator");
    List<String> history = (List<String>) session.getAttribute("history");

    if (num1   == null) num1  = "";
    if (num2   == null) num2  = "";
    if (selOp  == null) selOp = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Java Calculator</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link href="https://fonts.googleapis.com/css2?family=Space+Mono:ital,wght@0,400;0,700;1,400&family=Unbounded:wght@300;400;700&display=swap" rel="stylesheet"/>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:       #f5f0e8;
      --card:     #fdfaf4;
      --ink:      #1a1a1a;
      --muted:    #888070;
      --border:   #d8d0be;
      --accent:   #c8401a;
      --accent2:  #2a6b3c;
      --shadow:   4px 4px 0px #1a1a1a;
      --radius:   0px;
    }

    html, body {
      min-height: 100vh;
      background: var(--bg);
      background-image:
        radial-gradient(circle at 1px 1px, var(--border) 1px, transparent 0);
      background-size: 28px 28px;
      font-family: 'Space Mono', monospace;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }

    /* ── LAYOUT ───────────────────────────────────────── */
    .wrapper {
      display: flex;
      gap: 24px;
      align-items: flex-start;
      animation: load .4s ease both;
    }
    @keyframes load {
      from { opacity:0; transform: translateY(16px); }
      to   { opacity:1; transform: translateY(0); }
    }

    /* ── CALCULATOR CARD ──────────────────────────────── */
    .calc {
      background: var(--card);
      border: 2px solid var(--ink);
      box-shadow: var(--shadow);
      width: 360px;
      padding: 28px;
    }

    .calc-header {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      margin-bottom: 24px;
      border-bottom: 2px solid var(--ink);
      padding-bottom: 12px;
    }

    .calc-title {
      font-family: 'Unbounded', sans-serif;
      font-weight: 700;
      font-size: 13px;
      letter-spacing: .1em;
      text-transform: uppercase;
      color: var(--ink);
    }

    .calc-sub {
      font-size: 10px;
      color: var(--muted);
      letter-spacing: .12em;
    }

    /* ── RESULT DISPLAY ───────────────────────────────── */
    .display {
      background: var(--ink);
      color: #f5f0e8;
      padding: 20px 18px 16px;
      margin-bottom: 20px;
      min-height: 88px;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      align-items: flex-end;
      position: relative;
      overflow: hidden;
    }

    .display::before {
      content: 'OUTPUT';
      position: absolute;
      top: 10px; left: 14px;
      font-size: 9px;
      letter-spacing: .2em;
      color: #555;
    }

    .display-expr {
      font-size: 11px;
      color: #888;
      margin-bottom: 6px;
      min-height: 16px;
      text-align: right;
      word-break: break-all;
    }

    .display-result {
      font-family: 'Unbounded', sans-serif;
      font-size: 36px;
      font-weight: 300;
      letter-spacing: -.02em;
      text-align: right;
      word-break: break-all;
      line-height: 1;
    }
    .display-result.has-result { color: #f5f0e8; }
    .display-result.has-error  { color: #ff7755; font-size: 14px; font-weight: 400; padding-top: 10px; }
    .display-result.empty      { color: #444; }

    /* ── FORM ─────────────────────────────────────────── */
    form { display: flex; flex-direction: column; gap: 14px; }

    .row { display: flex; gap: 10px; }

    label {
      display: block;
      font-size: 10px;
      letter-spacing: .14em;
      text-transform: uppercase;
      color: var(--muted);
      margin-bottom: 6px;
    }

    input[type="number"], select {
      width: 100%;
      padding: 11px 13px;
      border: 2px solid var(--border);
      background: #fff;
      font-family: 'Space Mono', monospace;
      font-size: 15px;
      color: var(--ink);
      outline: none;
      transition: border-color .15s;
      -moz-appearance: textfield;
      appearance: textfield;
    }
    input[type="number"]::-webkit-inner-spin-button { display: none; }
    input[type="number"]:focus, select:focus {
      border-color: var(--ink);
    }

    select {
      cursor: pointer;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%231a1a1a' stroke-width='2' fill='none'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: right 13px center;
      padding-right: 36px;
      -webkit-appearance: none;
      -moz-appearance: none;
      appearance: none;
    }

    .field { flex: 1; }

    /* ── BUTTONS ──────────────────────────────────────── */
    .btn-row { display: flex; gap: 10px; margin-top: 4px; }

    button {
      flex: 1;
      padding: 14px;
      font-family: 'Unbounded', sans-serif;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: .08em;
      text-transform: uppercase;
      cursor: pointer;
      border: 2px solid var(--ink);
      transition: transform .08s, box-shadow .08s;
    }

    .btn-calc {
      background: var(--accent);
      color: #fff;
      box-shadow: 3px 3px 0 var(--ink);
    }
    .btn-calc:hover  { transform: translate(-1px,-1px); box-shadow: 4px 4px 0 var(--ink); }
    .btn-calc:active { transform: translate(2px,2px);  box-shadow: 1px 1px 0 var(--ink); }

    .btn-clear {
      background: var(--card);
      color: var(--ink);
      box-shadow: 3px 3px 0 var(--ink);
    }
    .btn-clear:hover  { transform: translate(-1px,-1px); box-shadow: 4px 4px 0 var(--ink); }
    .btn-clear:active { transform: translate(2px,2px);  box-shadow: 1px 1px 0 var(--ink); }

    /* ── HISTORY PANEL ────────────────────────────────── */
    .history-panel {
      background: var(--card);
      border: 2px solid var(--ink);
      box-shadow: var(--shadow);
      width: 240px;
      padding: 20px;
    }

    .history-title {
      font-family: 'Unbounded', sans-serif;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: .12em;
      text-transform: uppercase;
      color: var(--ink);
      border-bottom: 2px solid var(--ink);
      padding-bottom: 10px;
      margin-bottom: 14px;
    }

    .history-empty {
      font-size: 11px;
      color: var(--muted);
      font-style: italic;
    }

    .history-list {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .history-item {
      font-size: 11px;
      color: var(--muted);
      padding: 8px 10px;
      border: 1px solid var(--border);
      background: var(--bg);
      line-height: 1.5;
      cursor: pointer;
      transition: border-color .12s, color .12s;
      word-break: break-all;
    }
    .history-item:hover { border-color: var(--ink); color: var(--ink); }

    .history-clear {
      margin-top: 12px;
      width: 100%;
      padding: 8px;
      font-family: 'Space Mono', monospace;
      font-size: 10px;
      letter-spacing: .1em;
      text-transform: uppercase;
      background: transparent;
      border: 1px solid var(--border);
      color: var(--muted);
      cursor: pointer;
      transition: border-color .12s, color .12s;
    }
    .history-clear:hover { border-color: var(--accent); color: var(--accent); }

    /* responsive */
    @media (max-width: 660px) {
      .wrapper { flex-direction: column; }
      .history-panel { width: 360px; }
    }
  </style>
</head>
<body>

<div class="wrapper">

  <!-- ── CALCULATOR ───────────────────────────── -->
  <div class="calc">

    <div class="calc-header">
      <span class="calc-title">Calculator</span>
      <span class="calc-sub">JSP + Embedded Tomcat</span>
    </div>

    <!-- Display -->
    <div class="display">
      <div class="display-expr">
        <% if (expr != null) { %><%= expr %><% } else { %>&nbsp;<% } %>
      </div>
      <% if (error != null) { %>
        <div class="display-result has-error"><%= error %></div>
      <% } else if (result != null) { %>
        <div class="display-result has-result"><%= result %></div>
      <% } else { %>
        <div class="display-result empty">0</div>
      <% } %>
    </div>

    <!-- Form -->
    <form method="post" action="calculate">

      <div class="row">
        <div class="field">
          <label>Number A</label>
          <input type="number" name="num1" step="any"
                 value="<%= num1 %>"
                 placeholder="0" required/>
        </div>
        <div class="field">
          <label>Number B</label>
          <input type="number" name="num2" step="any"
                 value="<%= num2 %>"
                 placeholder="0" required/>
        </div>
      </div>

      <div>
        <label>Operator</label>
        <select name="operator" required>
          <option value=""    <%= selOp.isEmpty()  ? "selected" : "" %>>— select —</option>
          <option value="+"  <%= selOp.equals("+") ? "selected" : "" %>>+ &nbsp; Add</option>
          <option value="-"  <%= selOp.equals("-") ? "selected" : "" %>>− &nbsp; Subtract</option>
          <option value="*"  <%= selOp.equals("*") ? "selected" : "" %>>× &nbsp; Multiply</option>
          <option value="/"  <%= selOp.equals("/") ? "selected" : "" %>>÷ &nbsp; Divide</option>
          <option value="%"  <%= selOp.equals("%") ? "selected" : "" %>>% &nbsp; Modulo</option>
          <option value="^"  <%= selOp.equals("^") ? "selected" : "" %>>^ &nbsp; Power</option>
        </select>
      </div>

      <div class="btn-row">
        <button type="submit" class="btn-calc">= Calculate</button>
        <button type="button" class="btn-clear"
                onclick="window.location='calculate'">Clear</button>
      </div>

    </form>
  </div>

  <!-- ── HISTORY ──────────────────────────────── -->
  <div class="history-panel">
    <div class="history-title">History</div>

    <% if (history == null || history.isEmpty()) { %>
      <p class="history-empty">No calculations yet.</p>
    <% } else { %>
      <ul class="history-list">
        <% for (String h : history) { %>
          <li class="history-item"><%= h %></li>
        <% } %>
      </ul>
      <form method="post" action="calculate">
        <input type="hidden" name="clearHistory" value="true"/>
        <button type="submit" class="history-clear">✕ Clear history</button>
      </form>
    <% } %>
  </div>

</div>

</body>
</html>
