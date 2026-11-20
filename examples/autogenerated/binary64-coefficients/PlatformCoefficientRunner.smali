.class public LPlatformCoefficientRunner;
.super Ljava/lang/Object;

# Independent expectations for the actual checked source. No candidate parser,
# arithmetic or platform binding is produced by this observation runner.
.method private static check(Ljava/lang/String;ILjava/lang/String;)V
    .registers 7
    invoke-static {p0}, LIdric/Generated;->coefficient_observation(Ljava/lang/String;)I
    move-result v0
    if-ne v0, p1, :failed
    invoke-static {p0}, LIdric/Generated;->parsed_coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
  :failed
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL pure platform coefficient observation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const-string v0, "0.4"
    const/4 v1, 1
    const-string v2, "3fd999999999999a"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "16777217"
    const/4 v1, 2
    const-string v2, "4170000010000000"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "4.9406564584124654e-324"
    const/4 v1, 4
    const-string v2, "1"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "-0.0"
    const/16 v1, 8
    const-string v2, "8000000000000000"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "1e309"
    const/16 v1, 16
    const-string v2, "7ff0000000000000"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "0.25"
    const/16 v1, 224
    const-string v2, "3fd0000000000000"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    const-string v0, "3"
    const/16 v1, 256
    const-string v2, "4008000000000000"
    invoke-static {v0, v1, v2}, LPlatformCoefficientRunner;->check(Ljava/lang/String;ILjava/lang/String;)V
    invoke-static {v0}, LIdric/Generated;->squared_coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "4022000000000000"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :bad_square
    const-string v0, "NaN"
    invoke-static {v0}, LIdric/Generated;->parsed_coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "7ff8000000000000"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :bad_square
  :try_start
    const-string v0, "not-a-number"
    invoke-static {v0}, LIdric/Generated;->parsed_coefficient_bits(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
  :try_end
    .catch Ljava/lang/NumberFormatException; {:try_start .. :try_end} :caught_number_format
    const/16 v0, 75
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
  :bad_square
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL platform coefficient bit observation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 74
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
  :caught_number_format
    move-exception v0
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS pure checked platform coefficients on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
