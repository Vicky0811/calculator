package com.calculator;

public class Calculator {
    public double add(double a, double b)      { return a + b; }
    public double subtract(double a, double b) { return a - b; }
    public double multiply(double a, double b) { return a * b; }

    public double divide(double a, double b) {
        if (b == 0) throw new ArithmeticException("Cannot divide by zero");
        return a / b;
    }

    public double modulo(double a, double b) {
        if (b == 0) throw new ArithmeticException("Cannot modulo by zero");
        return a % b;
    }

    public double power(double base, double exp) { return Math.pow(base, exp); }

    public double squareRoot(double a) {
        if (a < 0) throw new ArithmeticException("Cannot sqrt negative number");
        return Math.sqrt(a);
    }

    public double evaluate(double a, String op, double b) {
        switch (op) {
            case "+": return add(a, b);
            case "-": return subtract(a, b);
            case "*": return multiply(a, b);
            case "/": return divide(a, b);
            case "%": return modulo(a, b);
            case "^": return power(a, b);
            default:  throw new IllegalArgumentException("Unknown operator: " + op);
        }
    }
}