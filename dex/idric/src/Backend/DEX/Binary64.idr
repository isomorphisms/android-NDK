module Backend.DEX.Binary64

%default total

private
fraction_scale : Integer
fraction_scale = 4503599627370496 -- 2^52, the stored binary64 fraction width.

private
sign_bit : Integer
sign_bit = 9223372036854775808 -- 2^63.

private
infinity_bits : Integer
infinity_bits = 9218868437227405312 -- exponent 2047, zero fraction.

private
power_of_two : Nat -> Integer
power_of_two Z = 1
power_of_two (S remaining) = 2 * power_of_two remaining

-- Scaling by two is exact in binary64. Even the least positive subnormal
-- needs only 1074 steps to reach [1,2); 2200 also covers the opposite direction.
private
normalize : Nat -> Double -> Int -> Either String (Double, Int)
normalize Z value exponent = Left "Binary64 literal normalization exhausted its IEEE exponent bound"
normalize (S remaining) value exponent =
  if value >= 2.0 then normalize remaining (value / 2.0) (exponent + 1)
  else if value < 1.0 then normalize remaining (value * 2.0) (exponent - 1)
  else Right (value, exponent)

||| Encode a source Double without decimal reprinting or a host-endian bitcast.
||| Nonfinite NaNs have one canonical quiet representation; payloads are not an
||| Idriç source value distinction. Signed zeros and infinities remain distinct.
public export
binary64_literal_bits : Double -> Either String Integer
binary64_literal_bits value =
  if not (value == value) then Right (infinity_bits + 2251799813685248)
  else
    let negative = value < 0.0 || (value == 0.0 && 1.0 / value < 0.0)
        sign = if negative then sign_bit else 0
        magnitude = if value < 0.0 then negate value else value in
    if magnitude == 0.0 then Right sign
    else if magnitude > 1.7976931348623157e308 then Right (sign + infinity_bits)
    else do
      (normalized, exponent) <- normalize 2200 magnitude 0
      let significand : Integer = cast (normalized * 4503599627370496.0)
      if significand < fraction_scale || significand >= 2 * fraction_scale ||
         exponent < -1074 || exponent > 1023
        then Left "Binary64 literal is outside its IEEE representation"
        else if exponent >= -1022
          then Right (sign + cast (exponent + 1023) * fraction_scale +
                      (significand - fraction_scale))
          else Right (sign + significand `div` power_of_two (cast (-1022 - exponent)))
