package com.calculator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Calculator Unit Tests")
class CalculatorTest {

    private Calculator calc;

    @BeforeEach
    void setUp() { calc = new Calculator(); }

    @Test @DisplayName("Add: 4 + 6 = 10")
    void testAdd() { assertEquals(10.0, calc.add(4, 6)); }

    @Test @DisplayName("Add: negatives")
    void testAddNeg() { assertEquals(-3.0, calc.add(-1, -2)); }

    @Test @DisplayName("Subtract: 8 - 5 = 3")
    void testSubtract() { assertEquals(3.0, calc.subtract(8, 5)); }

    @Test @DisplayName("Subtract: gives negative")
    void testSubtractNeg() { assertEquals(-2.0, calc.subtract(3, 5)); }

    @Test @DisplayName("Multiply: 4 × 5 = 20")
    void testMultiply() { assertEquals(20.0, calc.multiply(4, 5)); }

    @Test @DisplayName("Multiply by zero = 0")
    void testMultiplyZero() { assertEquals(0.0, calc.multiply(999, 0)); }

    @Test @DisplayName("Divide: 20 / 5 = 4")
    void testDivide() { assertEquals(4.0, calc.divide(20, 5)); }

    @Test @DisplayName("Divide by zero → ArithmeticException")
    void testDivideByZero() {
        assertThrows(ArithmeticException.class, () -> calc.divide(10, 0));
    }

    @Test @DisplayName("Modulo: 10 % 3 = 1")
    void testModulo() { assertEquals(1.0, calc.modulo(10, 3)); }

    @Test @DisplayName("Modulo by zero → ArithmeticException")
    void testModuloByZero() {
        assertThrows(ArithmeticException.class, () -> calc.modulo(5, 0));
    }

    @Test @DisplayName("Power: 2 ^ 10 = 1024")
    void testPower() { assertEquals(1024.0, calc.power(2, 10)); }

    @Test @DisplayName("Power: anything ^ 0 = 1")
    void testPowerZero() { assertEquals(1.0, calc.power(999, 0)); }

    @Test @DisplayName("Sqrt: √144 = 12")
    void testSqrt() { assertEquals(12.0, calc.squareRoot(144)); }

    @Test @DisplayName("Sqrt: negative → ArithmeticException")
    void testSqrtNeg() {
        assertThrows(ArithmeticException.class, () -> calc.squareRoot(-4));
    }

    @Test @DisplayName("evaluate: dispatch + operator")
    void testEvaluatePlus() { assertEquals(15.0, calc.evaluate(10, "+", 5)); }

    @Test @DisplayName("evaluate: unknown operator → IllegalArgumentException")
    void testEvaluateUnknown() {
        assertThrows(IllegalArgumentException.class, () -> calc.evaluate(1, "?", 1));
    }
}
