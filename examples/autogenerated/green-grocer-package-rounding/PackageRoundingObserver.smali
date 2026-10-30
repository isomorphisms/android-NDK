# Independent observation caller only. No candidate implementation is assembled.
.class public LPackageRoundingObserver;
.super Ljava/lang/Object;

.method private static check(II)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->packages(I)I
    move-result v0
    if-eq v0, p1, :ok
    new-instance v0, Ljava/lang/AssertionError;
    const-string v1, "wrong exact package count"
    invoke-direct {v0, v1}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v0
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const/4 v0, -0x1
    const/4 v1, -0x1
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/4 v0, 0x0
    const/4 v1, 0x0
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/4 v0, 0x1
    const/4 v1, 0x1
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/16 v0, 0x12c
    const/4 v1, 0x1
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/16 v0, 0x12d
    const/4 v1, 0x2
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/16 v0, 0x1f4
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/16 v0, 0x258
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    const/16 v0, 0x259
    const/4 v1, 0x3
    invoke-static {v0, v1}, LPackageRoundingObserver;->check(II)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS exact package rounding under ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
