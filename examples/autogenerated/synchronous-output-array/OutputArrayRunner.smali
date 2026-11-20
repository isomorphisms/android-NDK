.class public Lqualification/OutputArrayRunner;
.super Ljava/lang/Object;

.method private static equal(II)V
    .registers 4
    if-eq p0, p1, :ok
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL synchronous output-array JNI"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 83
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const/4 v0, 0
    aget-object v1, p0, v0
    const-string v2, "renderoutput.library"
    invoke-static {v2, v1}, Ljava/lang/System;->setProperty(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    invoke-static {v0}, LIdric/Generated;->render_probe(I)I
    move-result v1
    const v2, 0x12345678
    invoke-static {v1, v2}, Lqualification/OutputArrayRunner;->equal(II)V
    const/4 v0, 4
    new-array v1, v0, [I
    invoke-static {v1}, LIdric/Generated;->render_into([I)I
    move-result v0
    const/4 v2, 0
    invoke-static {v0, v2}, Lqualification/OutputArrayRunner;->equal(II)V
    aget v0, v1, v2
    const v3, 0x12345678
    invoke-static {v0, v3}, Lqualification/OutputArrayRunner;->equal(II)V
    const/4 v2, 1
    aget v0, v1, v2
    const/4 v3, -1
    invoke-static {v0, v3}, Lqualification/OutputArrayRunner;->equal(II)V
    const/4 v2, 2
    aget v0, v1, v2
    const/high16 v3, -0x80000000
    invoke-static {v0, v3}, Lqualification/OutputArrayRunner;->equal(II)V
    const/4 v2, 3
    aget v0, v1, v2
    const/16 v3, 17
    invoke-static {v0, v3}, Lqualification/OutputArrayRunner;->equal(II)V
    const/4 v1, 0
  :null_begin
    invoke-static {v1}, LIdric/Generated;->render_into([I)I
    move-result v0
  :null_end
    const/4 v2, 1
    const/4 v3, 0
    invoke-static {v2, v3}, Lqualification/OutputArrayRunner;->equal(II)V
    goto :complete
  :null_rejected
    move-exception v0
  :complete
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS synchronous output-array JNI on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
    .catch Ljava/lang/NullPointerException; {:null_begin .. :null_end} :null_rejected
.end method
