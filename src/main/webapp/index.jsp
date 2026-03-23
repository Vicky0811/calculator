<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%
    String result  = (String) request.getAttribute("result");
    String expr    = (String) request.getAttribute("expression");
    String error   = (String) request.getAttribute("error");
    String num1    = (String) request.getAttribute("num1");
    String num2    = (String) request.getAttribute("num2");
    String selOp   = (String) request.getAttribute("operator");
    List<String> history = (List<String>) session.getAttribute("history");
    if (num1  == null) num1  = "";
    if (num2  == null) num2  = "";
    if (selOp == null) selOp = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Java Calculator</title>
  <link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Unbounded:wght@400;700&display=swap" rel="stylesheet"/>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    :root{--bg:#f5f0e8;--card:#fdfaf4;--ink:#1a1a1a;--muted:#888070;--border:#d8d0be;--accent:#c8401a;--shadow:4px 4px 0 #1a1a1a}
    body{min-height:100vh;background:var(--bg);background-image:radial-gradient(circle at 1px 1px,var(--border) 1px,transparent 0);background-size:28px 28px;font-family:'Space Mono',monospace;display:flex;align-items:center;justify-content:center;padding:24px}
    .wrapper{display:flex;gap:24px;align-items:flex-start}
    .calc{background:var(--card);border:2px solid var(--ink);box-shadow:var(--shadow);width:360px;padding:28px}
    .calc-header{display:flex;justify-content:space-between;align-items:baseline;border-bottom:2px solid var(--ink);padding-bottom:12px;margin-bottom:24px}
    .calc-title{font-family:'Unbounded',sans-serif;font-weight:700;font-size:13px;letter-spacing:.1em;text-transform:uppercase}
    .display{background:var(--ink);color:#f5f0e8;padding:20px 18px 16px;margin-bottom:20px;min-height:88px;display:flex;flex-direction:column;justify-content:flex-end;align-items:flex-end;position:relative}
    .display::before{content:'OUTPUT';position:absolute;top:10px;left:14px;font-size:9px;letter-spacing:.2em;color:#555}
    .display-expr{font-size:11px;color:#888;margin-bottom:6px;text-align:right}
    .display-result{font-family:'Unbounded',sans-serif;font-size:36px;font-weight:300;text-align:right;word-break:break-all}
    .has-error{color:#ff7755;font-size:14px}
    .empty{color:#444}
    form{display:flex;flex-direction:column;gap:14px}
    .row{display:flex;gap:10px}
    label{display:block;font-size:10px;letter-spacing:.14em;text-transform:uppercase;color:var(--muted);margin-bottom:6px}
    input,select{width:100%;padding:11px 13px;border:2px solid var(--border);background:#fff;font-family:'Space Mono',monospace;font-size:15px;color:var(--ink);outline:none}
    input:focus,select:focus{border-color:var(--ink)}
    select{cursor:pointer;-webkit-appearance:none;appearance:none}
    .field{flex:1}
    .btn-row{display:flex;gap:10px;margin-top:4px}
    button{flex:1;padding:14px;font-family:'Unbounded',sans-serif;font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;cursor:pointer;border:2px solid var(--ink);transition:transform .08s,box-shadow .08s}
    .btn-calc{background:var(--accent);color:#fff;box-shadow:3px 3px 0 var(--ink)}
    .btn-calc:hover{transform:translate(-1px,-1px);box-shadow:4px 4px 0 var(--ink)}
    .btn-calc:active{transform:translate(2px,2px);box-shadow:1px 1px 0 var(--ink)}
    .btn-clear{background:var(--card);color:var(--ink);box-shadow:3px 3px 0 var(--ink)}
    .btn-clear:hover{transform:translate(-1px,-1px);box-shadow:4px 4px 0 var(--ink)}
    .history-panel{background:var(--card);border:2px solid var(--ink);box-shadow:var(--shadow);width:240px;padding:20px}
    .history-title{font-family:'Unbounded',sans-serif;font-size:11px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;border-bottom:2px solid var(--ink);padding-bottom:10px;margin-bottom:14px}
    .history-list{list-style:none;display:flex;flex-direction:column;gap:8px}
    .history-item{font-size:11px;color:var(--muted);padding:8px 10px;border:1px solid var(--border);background:var(--bg);word-break:break-all}
    .history-empty{font-size:11px;color:var(--muted);font-style:italic}
  </style>
</head>
<body>
<div class="wrapper">
  <div class="calc">
    <div class="calc-header">
      <span class="calc-title">Calculator</span>
      <span style="font-size:10px;color:var(--muted)">JSP + K8s</span>
    </div>
    <div class="display">
      <div class="display-expr"><% if(expr!=null){%><%=expr%><%}else{%>&nbsp;<%}%></div>
      <%if(error!=null){%><div class="display-result has-error"><%=error%></div>
      <%}else if(result!=null){%><div class="display-result"><%=result%></div>
      <%}else{%><div class="display-result empty">0</div><%}%>
    </div>
    <form method="post" action="calculate">
      <div class="row">
        <div class="field"><label>Number A</label><input type="number" name="num1" step="any" value="<%=num1%>" placeholder="0" required/></div>
        <div class="field"><label>Number B</label><input type="number" name="num2" step="any" value="<%=num2%>" placeholder="0" required/></div>
      </div>
      <div>
        <label>Operator</label>
        <select name="operator" required>
          <option value="" <%=selOp.isEmpty()?"selected":""%>>— select —</option>
          <option value="+" <%=selOp.equals("+")?"selected":""%>>+  Add</option>
          <option value="-" <%=selOp.equals("-")?"selected":""%>>−  Subtract</option>
          <option value="*" <%=selOp.equals("*")?"selected":""%>>×  Multiply</option>
          <option value="/" <%=selOp.equals("/")?"selected":""%>>÷  Divide</option>
          <option value="%" <%=selOp.equals("%")?"selected":""%>>%  Modulo</option>
          <option value="^" <%=selOp.equals("^")?"selected":""%>>^  Power</option>
        </select>
      </div>
      <div class="btn-row">
        <button type="submit" class="btn-calc">= Calculate</button>
        <button type="button" class="btn-clear" onclick="window.location='calculate'">Clear</button>
      </div>
    </form>
  </div>
  <div class="history-panel">
    <div class="history-title">History</div>
    <%if(history==null||history.isEmpty()){%>
      <p class="history-empty">No calculations yet.</p>
    <%}else{%>
      <ul class="history-list">
        <%for(String h:history){%><li class="history-item"><%=h%></li><%}%>
      </ul>
    <%}%>
  </div>
</div>
</body>
</html>