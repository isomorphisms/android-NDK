.class public final Lacceptance/ProjectionExportObserver;
.super Ljava/lang/Object;

.method private static expect(Ljava/lang/String;Ljava/lang/String;)V
    .registers 5
    invoke-static {p0}, LIdric/Generated;->source_title(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :passed
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL unchanged IB retained-source export"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :passed
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const-string v0, "<html><head><title>One document</title></head><body>A</body></html>"
    const-string v1, "One document"
    invoke-static {v0, v1}, Lacceptance/ProjectionExportObserver;->expect(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "<html><head><title>café 🦉</title></head><body>λ</body></html>"
    const-string v1, "café 🦉"
    invoke-static {v0, v1}, Lacceptance/ProjectionExportObserver;->expect(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "<html><head><title>Another source</title></head><body>B</body></html>"
    const-string v1, "Another source"
    invoke-static {v0, v1}, Lacceptance/ProjectionExportObserver;->expect(Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS unchanged IB source projection on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
