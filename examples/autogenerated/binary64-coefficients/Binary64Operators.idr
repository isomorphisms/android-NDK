module Binary64Operators

%default total

-- Pinned-frontend primitive-operator compatibility only. The current snapshot
-- does not admit Unicode infix declarations in either source stratum. The
-- application-facing .idric probe uses descriptive coefficient operations.

export
subtract_coefficients : Double -> Double -> Double
subtract_coefficients left right = left - right

export
multiply_coefficients : Double -> Double -> Double
multiply_coefficients left right = left * right

export
divide_coefficients : Double -> Double -> Double
divide_coefficients left right = left / right
