.class public LFormattedResourcesRunner;
.super Ljava/lang/Object;

.method private static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked SDK format arguments"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 89
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static same(Ljava/lang/String;Ljava/lang/String;)V
    .registers 3
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    invoke-static {}, LFormattedResourcesRunner;->fail()V
  :ok
    return-void
.end method

.method private static observe()V
    .registers 8
    sget-object v0, Ljava/util/Locale;->US:Ljava/util/Locale;
    invoke-static {v0}, Ljava/util/Locale;->setDefault(Ljava/util/Locale;)V
    const-string v0, "%2$04d|%1$d|%3$s|%1$04x"
    const/16 v1, 23
    const/4 v2, 5
    const-string v3, "λ😀 %1$s"
    invoke-static {v0, v1, v2, v3}, LIdric/Generated;->format_argument_order(Ljava/lang/String;IILjava/lang/String;)Ljava/lang/String;
    move-result-object v4
    const-string v5, "0005|23|λ😀 %1$s|0017"
    invoke-static {v5, v4}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "%3$s %2$d %1$d %2$d"
    const/4 v1, -7
    const/16 v2, 101
    const-string v3, "error λ"
    invoke-static {v0, v1, v2, v3}, LIdric/Generated;->format_argument_order(Ljava/lang/String;IILjava/lang/String;)Ljava/lang/String;
    move-result-object v4
    const-string v5, "error λ 101 -7 101"
    invoke-static {v5, v4}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "%1$d,%2$d,%3$s"
    const v1, -2147483648
    const v2, 2147483647
    const-string v3, ""
    invoke-static {v0, v1, v2, v3}, LIdric/Generated;->format_argument_order(Ljava/lang/String;IILjava/lang/String;)Ljava/lang/String;
    move-result-object v4
    const-string v5, "-2147483648,2147483647,"
    invoke-static {v5, v4}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "%2$d ms / %1$d"
    const/4 v1, 3
    const-wide v2, 0x0000000080000000L
    invoke-static {v0, v1, v2, v3}, LIdric/Generated;->format_complete_arguments(Ljava/lang/String;IJ)Ljava/lang/String;
    move-result-object v4
    const-string v5, "2147483648 ms / 3"
    invoke-static {v5, v4}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V

    # Exercise the actual Resources overload without choosing application text.
    # Application resource-format contents remain an installed-app observation.
    invoke-static {}, Landroid/content/res/Resources;->getSystem()Landroid/content/res/Resources;
    move-result-object v0
    const-string v1, "ok"
    const-string v2, "string"
    const-string v3, "android"
    invoke-virtual {v0, v1, v2, v3}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v1
    if-gtz v1, :resource_found
    invoke-static {}, LFormattedResourcesRunner;->fail()V
  :resource_found
    invoke-virtual {v0, v1}, Landroid/content/res/Resources;->getString(I)Ljava/lang/String;
    move-result-object v6
    const/16 v2, 144
    const/16 v3, 32
    invoke-static {v0, v1, v2, v3}, LIdric/Generated;->format_rendering_status(Landroid/content/res/Resources;III)Ljava/lang/String;
    move-result-object v4
    invoke-static {v6, v4}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const/4 v2, 3
    const-wide v3, 0x0000000080000000L
    invoke-static {v0, v1, v2, v3, v4}, LIdric/Generated;->format_complete_status(Landroid/content/res/Resources;IIJ)Ljava/lang/String;
    move-result-object v5
    invoke-static {v6, v5}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v2, "source error %1$s λ😀"
    invoke-static {v0, v1, v2}, LIdric/Generated;->format_formula_error(Landroid/content/res/Resources;ILjava/lang/String;)Ljava/lang/String;
    move-result-object v5
    invoke-static {v6, v5}, LFormattedResourcesRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked SDK format arguments"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :start
    invoke-static {}, LFormattedResourcesRunner;->observe()V
  :end
    return-void
    .catch Ljava/lang/Throwable; {:start .. :end} :unexpected
  :unexpected
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V
    const/16 v1, 90
    invoke-static {v1}, Ljava/lang/System;->exit(I)V
    return-void
.end method
