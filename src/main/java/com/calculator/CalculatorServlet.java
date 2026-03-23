package com.calculator;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/calculate")
public class CalculatorServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final Calculator calculator = new Calculator();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher("/index.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String num1Str  = req.getParameter("num1");
        String num2Str  = req.getParameter("num2");
        String operator = req.getParameter("operator");

        if (isBlank(num1Str) || isBlank(num2Str) || isBlank(operator)) {
            req.setAttribute("error", "Please fill in both numbers and choose an operator.");
            req.getRequestDispatcher("/index.jsp").forward(req, resp);
            return;
        }

        double a, b;
        try {
            a = Double.parseDouble(num1Str.trim());
            b = Double.parseDouble(num2Str.trim());
        } catch (NumberFormatException e) {
            req.setAttribute("error", "Invalid number — please enter numeric values.");
            req.setAttribute("num1", num1Str);
            req.setAttribute("num2", num2Str);
            req.setAttribute("operator", operator);
            req.getRequestDispatcher("/index.jsp").forward(req, resp);
            return;
        }

        try {
            double result = calculator.evaluate(a, operator, b);
            String formatted = formatResult(result);
            String expression = formatNum(a) + " " + opSymbol(operator)
                              + " " + formatNum(b) + " = " + formatted;

            req.setAttribute("result", formatted);
            req.setAttribute("expression", expression);
            req.setAttribute("num1", formatNum(a));
            req.setAttribute("num2", formatNum(b));
            req.setAttribute("operator", operator);

            HttpSession session = req.getSession();
            List<String> history = (List<String>) session.getAttribute("history");
            if (history == null) history = new ArrayList<>();
            history.add(0, expression);
            if (history.size() > 10) history = history.subList(0, 10);
            session.setAttribute("history", history);

        } catch (ArithmeticException | IllegalArgumentException e) {
            req.setAttribute("error", e.getMessage());
            req.setAttribute("num1", formatNum(a));
            req.setAttribute("num2", formatNum(b));
            req.setAttribute("operator", operator);
        }

        req.getRequestDispatcher("/index.jsp").forward(req, resp);
    }

    private String formatResult(double v) {
        if (Double.isInfinite(v) || Double.isNaN(v)) return "Error";
        if (v == Math.floor(v) && Math.abs(v) < 1e15) return String.valueOf((long) v);
        return String.valueOf(v);
    }

    private String formatNum(double v) {
        if (v == Math.floor(v) && Math.abs(v) < 1e15) return String.valueOf((long) v);
        return String.valueOf(v);
    }

    private String opSymbol(String op) {
        switch (op) {
            case "+": return "+";  case "-": return "−";
            case "*": return "×";  case "/": return "÷";
            case "%": return "mod"; case "^": return "^";
            default:  return op;
        }
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}