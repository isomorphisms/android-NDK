.class public LInt32CoefficientRunner;
.super Ljava/lang/Object;

# Expected IEEE bits are independent constants. The checked source receives a
# primitive signed Int32 from this caller and performs the numerical conversion.
.method private static check(ILjava/lang/String;)V
    .registers 5
    invoke-static {p0}, LIdric/Generated;->int32_coefficient_bits(I)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked Int32 coefficient observation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(I)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const v0, -0x80000000
    const-string v1, "c1e0000000000000"
    invoke-static {v0, v1}, LInt32CoefficientRunner;->check(ILjava/lang/String;)V
    const v0, 0x7fffffff
    const-string v1, "41dfffffffc00000"
    invoke-static {v0, v1}, LInt32CoefficientRunner;->check(ILjava/lang/String;)V
    const/4 v0, 0
    const-string v1, "0"
    invoke-static {v0, v1}, LInt32CoefficientRunner;->check(ILjava/lang/String;)V
    const/4 v0, -1
    const-string v1, "bff0000000000000"
    invoke-static {v0, v1}, LInt32CoefficientRunner;->check(ILjava/lang/String;)V
    const v0, 0x1000001
    const-string v1, "4170000010000000"
    invoke-static {v0, v1}, LInt32CoefficientRunner;->check(ILjava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked Int32 coefficients on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
