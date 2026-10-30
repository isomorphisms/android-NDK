.class public Lacceptance/RuntimeArgObserver;
.super Ljava/lang/Object;

# This harness has no Idric application code. It calls the production direct
# DEX main([String]), which initializes private static argv before a checked
# entrypoint, then independently observes the count and 64-bit indexed reads.
.method public static main([Ljava/lang/String;)V
    .registers 11

    invoke-static {p0}, LIdric/RuntimeArguments;->main([Ljava/lang/String;)V
    array-length v0, p0
    if-eqz v0, :zero_arguments
    const/4 v1, 0x2
    if-ne v0, v1, :bad_result

    invoke-static {}, LIdric/RuntimeArguments;->__idricArgCount()J
    move-result-wide v2
    const-wide/16 v4, 0x3
    cmp-long v6, v2, v4
    if-nez v6, :bad_result

    const-wide/16 v2, 0x0
    invoke-static {v2, v3}, LIdric/RuntimeArguments;->__idricArg(J)Ljava/lang/String;
    move-result-object v7
    const-string v8, "icu"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    const-wide/16 v2, 0x1
    invoke-static {v2, v3}, LIdric/RuntimeArguments;->__idricArg(J)Ljava/lang/String;
    move-result-object v7
    const-string v8, "first"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    const-wide/16 v2, 0x2
    invoke-static {v2, v3}, LIdric/RuntimeArguments;->__idricArg(J)Ljava/lang/String;
    move-result-object v7
    const-string v8, "second"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    sget-object v7, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v8, "PASS runtime argv: two program arguments"
    invoke-virtual {v7, v8}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

:zero_arguments
    invoke-static {}, LIdric/RuntimeArguments;->__idricArgCount()J
    move-result-wide v2
    const-wide/16 v4, 0x1
    cmp-long v6, v2, v4
    if-nez v6, :bad_result

    const-wide/16 v2, 0x0
    invoke-static {v2, v3}, LIdric/RuntimeArguments;->__idricArg(J)Ljava/lang/String;
    move-result-object v7
    const-string v8, "icu"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    sget-object v7, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v8, "PASS runtime argv: zero program arguments"
    invoke-virtual {v7, v8}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

:bad_result
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method
