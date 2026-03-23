package com.calculator;

import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Calculator Unit Tests")
class CalculatorTest {

    private Calculator calc;

    @BeforeEach
    void setUp() { calc = new Calculator(); }

    @Test void testAdd()          { assertEquals(10.0, calc.add(4, 6)); }
    @Test void testSubtract()     { assertEquals(3.0,  calc.subtract(8, 5)); }
    @Test void testMultiply()     { assertEquals(20.0, calc.multiply(4, 5)); }
    @Test void testDivide()       { assertEquals(4.0,  calc.divide(20, 5)); }
    @Test void testModulo()       { assertEquals(1.0,  calc.modulo(10, 3)); }
    @Test void testPower()        { assertEquals(1024.0, calc.power(2, 10)); }
    @Test void testSqrt()         { assertEquals(12.0, calc.squareRoot(144)); }

    @Test void testDivideByZero() {
        assertThrows(ArithmeticException.class, () -> calc.divide(10, 0));
    }
    @Test void testSqrtNegative() {
        assertThrows(ArithmeticException.class, () -> calc.squareRoot(-4));
    }
    @Test void testEvaluatePlus() {
        assertEquals(15.0, calc.evaluate(10, "+", 5));
    }
}