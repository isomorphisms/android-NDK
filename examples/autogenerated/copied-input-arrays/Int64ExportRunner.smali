.class public Lqualification/Int64ExportRunner;
.super Ljava/lang/Object;

.method private static checkIO(J)V
    .registers 5
    invoke-static {p0, p1}, LIdric/Generated;->int64_io_identity(J)J
    move-result-wide v0
    cmp-long v2, v0, p0
    if-eqz v2, :ok
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :ok
    return-void
.end method

.method private static checkSnapshot(JJ)V
    .registers 10
    const-wide/16 v0, 0
    cmp-long v2, p0, v0
    if-gtz v2, :count
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :count
    invoke-static {p0, p1}, LIdric/Generated;->coefficientCount(J)I
    move-result v0
    const/4 v1, 4
    if-eq v0, v1, :bits
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :bits
    const/4 v0, 0
    invoke-static {p0, p1, v0}, LIdric/Generated;->coefficientBits(JI)J
    move-result-wide v0
    cmp-long v2, v0, p2
    if-eqz v2, :release
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :release
    invoke-static {p0, p1}, LIdric/Generated;->releaseSurface(J)V
    invoke-static {}, LIdric/Generated;->lastHandle()J
    move-result-wide v0
    const-wide/16 v2, 0
    cmp-long v4, v0, v2
    if-eqz v4, :ok
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    invoke-static {p0}, Lqualification/Int64IdentityObserver;->main([Ljava/lang/String;)V
    const-wide/high16 v0, -0x8000000000000000L
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const-wide v0, 0x7fffffffffffffffL
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const-wide/16 v0, -1
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const-wide/16 v0, 0
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const-wide/16 v0, 1
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const-wide v0, 0x100000001L
    invoke-static {v0, v1}, Lqualification/Int64ExportRunner;->checkIO(J)V
    const v0, 0x1000001
    invoke-static {v0}, LIdric/Generated;->create_surface_handle(I)J
    move-result-wide v0
    const-wide v2, 0x4170000010000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/Int64ExportRunner;->checkSnapshot(JJ)V
    const-string v0, "wide"
    invoke-static {v0}, LIdric/Generated;->actual_prepare_handle(Ljava/lang/String;)J
    move-result-wide v0
    const-wide v2, 0x4170000010000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/Int64ExportRunner;->checkSnapshot(JJ)V
    const-string v0, "negative"
    invoke-static {v0}, LIdric/Generated;->actual_prepare_handle(Ljava/lang/String;)J
    move-result-wide v0
    const-wide v2, -0x4010000000000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/Int64ExportRunner;->checkSnapshot(JJ)V
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v0
    const-wide/16 v2, 3
    cmp-long v0, v0, v2
    if-eqz v0, :ok
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :ok
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked Int64 handle exports on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
