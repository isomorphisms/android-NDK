.class public Lacceptance/ArgumentIndexObserver;
.super Ljava/lang/Object;

.method private static number(Ljava/lang/String;)Ljava/math/BigInteger;
    .registers 2
    new-instance v0, Ljava/math/BigInteger;
    invoke-direct {v0, p0}, Ljava/math/BigInteger;-><init>(Ljava/lang/String;)V
    return-object v0
.end method

# Only the candidate owns argument storage/access. This oracle independently
# requires exceptions for negative, absent and overflowing source indices.
.method public static main([Ljava/lang/String;)V
    .registers 8
    invoke-static {p0}, LIdric/Generated;->main([Ljava/lang/String;)V

  :negative_start
    const-wide/16 v2, -0x1
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :negative_end
    goto :bad
  :negative_caught
    move-exception v0

  :absent_start
    const-wide/16 v2, 0x1
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :absent_end
    goto :bad
  :absent_caught
    move-exception v0

  :overflow_start
    const-wide v2, 0x80000000L
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :overflow_end
    goto :bad
  :overflow_caught
    move-exception v0

  :underflow_start
    const-wide v2, -0x8000000000000000L
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :underflow_end
    goto :bad
  :underflow_caught
    move-exception v0

    const-string v1, "2147483647"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricIntExact(Ljava/lang/Object;)I
    move-result v2
    const v3, 0x7fffffff
    if-ne v2, v3, :bad
    const-string v1, "-2147483648"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricIntExact(Ljava/lang/Object;)I
    move-result v2
    const v3, -0x80000000
    if-ne v2, v3, :bad
    const-string v1, "-9223372036854775808"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricLongExact(Ljava/lang/Object;)J
    move-result-wide v2
    const-wide v4, -0x8000000000000000L
    cmp-long v6, v2, v4
    if-nez v6, :bad
    const-string v1, "9223372036854775807"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricLongExact(Ljava/lang/Object;)J
    move-result-wide v2
    const-wide v4, 0x7fffffffffffffffL
    cmp-long v6, v2, v4
    if-nez v6, :bad

  :integer_overflow_start
    const-string v1, "2147483648"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricIntExact(Ljava/lang/Object;)I
  :integer_overflow_end
    goto :bad
  :integer_overflow_caught
    move-exception v0
  :integer_underflow_start
    const-string v1, "-2147483649"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricIntExact(Ljava/lang/Object;)I
  :integer_underflow_end
    goto :bad
  :integer_underflow_caught
    move-exception v0
  :long_overflow_start
    const-string v1, "9223372036854775808"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricLongExact(Ljava/lang/Object;)J
  :long_overflow_end
    goto :bad
  :long_overflow_caught
    move-exception v0
  :long_underflow_start
    const-string v1, "-9223372036854775809"
    invoke-static {v1}, Lacceptance/ArgumentIndexObserver;->number(Ljava/lang/String;)Ljava/math/BigInteger;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->__idricLongExact(Ljava/lang/Object;)J
  :long_underflow_end
    goto :bad
  :long_underflow_caught
    move-exception v0
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked argument index refusals"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

  :bad
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
    .catch Ljava/lang/IndexOutOfBoundsException; {:negative_start .. :negative_end} :negative_caught
    .catch Ljava/lang/IndexOutOfBoundsException; {:absent_start .. :absent_end} :absent_caught
    .catch Ljava/lang/ArithmeticException; {:overflow_start .. :overflow_end} :overflow_caught
    .catch Ljava/lang/ArithmeticException; {:underflow_start .. :underflow_end} :underflow_caught
    .catch Ljava/lang/ArithmeticException; {:integer_overflow_start .. :integer_overflow_end} :integer_overflow_caught
    .catch Ljava/lang/ArithmeticException; {:integer_underflow_start .. :integer_underflow_end} :integer_underflow_caught
    .catch Ljava/lang/ArithmeticException; {:long_overflow_start .. :long_overflow_end} :long_overflow_caught
    .catch Ljava/lang/ArithmeticException; {:long_underflow_start .. :long_underflow_end} :long_underflow_caught
.end method
