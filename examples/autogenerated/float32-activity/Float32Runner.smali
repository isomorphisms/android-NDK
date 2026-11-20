.class public Lqualification/Float32Runner;
.super Ljava/lang/Object;

.method private static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "FAIL checked Float32 source and platform boundary"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static checkBits(IIII)V
    .registers 6
    invoke-static {p0, p1, p2}, LIdric/Generated;->f32_calculate_bits(III)I
    move-result v0
    if-eq v0, p3, :done
    invoke-static {}, Lqualification/Float32Runner;->fail()V
  :done
    return-void
.end method

.method private static checkWidened(IIIJ)V
    .registers 9
    invoke-static {p0, p1, p2}, LIdric/Generated;->f32_calculate_widened_bits(III)J
    move-result-wide v0
    cmp-long v2, v0, p3
    if-eqz v2, :done
    invoke-static {}, Lqualification/Float32Runner;->fail()V
  :done
    return-void
.end method

.method private static checkEvent(IIJ)V
    .registers 8
    invoke-static {p0, p1}, LIdric/Generated;->f32_event_delta_bits(II)J
    move-result-wide v0
    cmp-long v2, v0, p2
    if-eqz v2, :done
    invoke-static {}, Lqualification/Float32Runner;->fail()V
  :done
    return-void
.end method

.method private static checkNaN(III)V
    .registers 7
    invoke-static {p0, p1, p2}, LIdric/Generated;->f32_calculate_bits(III)I
    move-result v0
    const v1, 0x7f800000
    and-int v2, v0, v1
    if-ne v2, v1, :bad
    const v1, 0x007fffff
    and-int v2, v0, v1
    if-nez v2, :done
  :bad
    invoke-static {}, Lqualification/Float32Runner;->fail()V
  :done
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 10
    # A finite tie: F32 subtract rounds to1, whereas widening operands first
    # gives Double1+2^-24. These expected bits do not call candidate arithmetic.
    const/4 v0, 1
    const v1, 0x3f800000
    const v2, 0xb3800000
    const v3, 0x3f800000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const-wide v3, 0x3ff0000000000000L
    invoke-static {v0, v1, v2, v3, v4}, Lqualification/Float32Runner;->checkWidened(IIIJ)V
    invoke-static {v1, v2, v3, v4}, Lqualification/Float32Runner;->checkEvent(IIJ)V

    const/4 v0, 0
    const v1, 0x3f800000
    const v2, 0x33800000
    const v3, 0x3f800000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V

    const/4 v0, 2
    const v1, 0x3fc00000
    const v2, 0x40000000
    const v3, 0x40400000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v0, 3
    const v1, 0x40400000
    const v2, 0x40000000
    const v3, 0x3fc00000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V

    # Signed zero: subtraction and multiplication retain a negative zero.
    const/4 v0, 1
    const v1, 0x80000000
    const/4 v2, 0
    const v3, 0x80000000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const-wide v3, 0x8000000000000000L
    invoke-static {v0, v1, v2, v3, v4}, Lqualification/Float32Runner;->checkWidened(IIIJ)V
    const/4 v0, 0
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v0, 2
    const v2, 0x3f800000
    const v3, 0x80000000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V

    # Subnormal ties and overflow remain primitive Float32 operations.
    const/4 v0, 0
    const/4 v1, 1
    const/4 v2, 1
    const/4 v3, 2
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v2, 0
    const-wide v3, 0x36a0000000000000L
    invoke-static {v0, v1, v2, v3, v4}, Lqualification/Float32Runner;->checkWidened(IIIJ)V
    const/4 v0, 2
    const v2, 0x3f000000
    const/4 v3, 0
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v0, 3
    const/4 v1, 3
    const v2, 0x40000000
    const/4 v3, 2
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v0, 2
    const v1, 0x7f7fffff
    const v2, 0x40000000
    const v3, 0x7f800000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V
    const/4 v0, 3
    const v1, 0x3f800000
    const v2, 0x80000000
    const v3, 0xff800000
    invoke-static {v0, v1, v2, v3}, Lqualification/Float32Runner;->checkBits(IIII)V

    # NaN classification only: no promise about a signaling NaN payload.
    const/4 v0, 1
    const v1, 0x7f800000
    const v2, 0x7f800000
    invoke-static {v0, v1, v2}, Lqualification/Float32Runner;->checkNaN(III)V
    const/4 v0, 3
    const/4 v1, 0
    const/4 v2, 0
    invoke-static {v0, v1, v2}, Lqualification/Float32Runner;->checkNaN(III)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked Float32 source and platform boundary"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
