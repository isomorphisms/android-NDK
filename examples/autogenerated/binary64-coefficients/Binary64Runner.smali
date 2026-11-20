.class public LBinary64Runner;
.super Ljava/lang/Object;

# Independent observer. Only this observer is assembled; candidate bytes must
# come from the checked Binary64Source.idric export.
.method private static check(Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->binary64_observation(Ljava/lang/String;)I
    move-result v0
    const/16 v1, 4095
    if-eq v0, v1, :ok
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL binary64 source observation"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(I)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const-string v0, "one"
    invoke-static {v0}, LBinary64Runner;->check(Ljava/lang/String;)V
    const-string v0, "two"
    invoke-static {v0}, LBinary64Runner;->check(Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked binary64 source on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
