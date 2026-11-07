.class public Lacceptance/ArgvObserver;
.super Ljava/lang/Object;

# An observation harness only. All argument-count and lookup methods come
# from the direct-DEX Idric/ArgvBoundary candidate, never from this runner.
.method public static main([Ljava/lang/String;)V
    .registers 11

    invoke-static {p0}, LIdric/ArgvBoundary;->rememberArguments([Ljava/lang/String;)V
    array-length v0, p0
    if-eqz v0, :zero_arguments
    const/4 v1, 0x2
    if-ne v0, v1, :bad_result

    invoke-static {p0}, LIdric/ArgvBoundary;->commandLineCount([Ljava/lang/String;)J
    move-result-wide v2
    const-wide/16 v4, 0x3
    cmp-long v6, v2, v4
    if-nez v6, :bad_result
    invoke-static {}, LIdric/ArgvBoundary;->savedCommandLineCount()J
    move-result-wide v2
    cmp-long v6, v2, v4
    if-nez v6, :bad_result

    const/4 v1, 0x0
    invoke-static {p0, v1}, LIdric/ArgvBoundary;->commandLineArg32([Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v7
    const-string v8, "icu"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    const/4 v1, 0x1
    invoke-static {p0, v1}, LIdric/ArgvBoundary;->commandLineArg32([Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v7
    const-string v8, "first"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    const/4 v1, 0x2
    invoke-static {v1}, LIdric/ArgvBoundary;->savedCommandLineArg32(I)Ljava/lang/String;
    move-result-object v7
    const-string v8, "second"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    invoke-static {p0, v1}, LIdric/ArgvBoundary;->commandLineArg32([Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v7
    const-string v8, "second"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    sget-object v7, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v8, "PASS argv: two program arguments"
    invoke-virtual {v7, v8}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

:zero_arguments
    invoke-static {p0}, LIdric/ArgvBoundary;->commandLineCount([Ljava/lang/String;)J
    move-result-wide v2
    const-wide/16 v4, 0x1
    cmp-long v6, v2, v4
    if-nez v6, :bad_result
    invoke-static {}, LIdric/ArgvBoundary;->savedCommandLineCount()J
    move-result-wide v2
    cmp-long v6, v2, v4
    if-nez v6, :bad_result

    const/4 v1, 0x0
    invoke-static {p0, v1}, LIdric/ArgvBoundary;->commandLineArg32([Ljava/lang/String;I)Ljava/lang/String;
    move-result-object v7
    const-string v8, "icu"
    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v9
    if-eqz v9, :bad_result

    sget-object v7, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v8, "PASS argv: zero program arguments"
    invoke-virtual {v7, v8}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

:bad_result
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method
