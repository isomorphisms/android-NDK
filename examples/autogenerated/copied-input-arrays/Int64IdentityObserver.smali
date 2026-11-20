.class public Lqualification/Int64IdentityObserver;
.super Ljava/lang/Object;

.method public static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked Int64 source exports"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static check(J)V
    .registers 8
    invoke-static {p0, p1}, LIdric/Generated;->int64_identity(J)J
    move-result-wide v0
    cmp-long v2, v0, p0
    if-eqz v2, :after
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :after
    const/16 v0, 17
    move-wide v1, p0
    invoke-static {v0, v1, v2}, LIdric/Generated;->int64_after_int32(IJ)J
    move-result-wide v3
    cmp-long v0, v3, p0
    if-eqz v0, :before
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :before
    move-wide v0, p0
    const/16 v2, 29
    invoke-static {v0, v1, v2}, LIdric/Generated;->int64_before_int32(JI)J
    move-result-wide v3
    cmp-long v0, v3, p0
    if-eqz v0, :first
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :first
    move-wide v0, p0
    const/4 v2, 0
    const-wide/16 v3, 42
    invoke-static {v0, v1, v2, v3, v4}, LIdric/Generated;->select_int64_argument(JIJ)J
    move-result-wide v0
    cmp-long v2, v0, p0
    if-eqz v2, :second
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :second
    move-wide v0, p0
    const/4 v2, 1
    const-wide/16 v3, 42
    invoke-static {v0, v1, v2, v3, v4}, LIdric/Generated;->select_int64_argument(JIJ)J
    move-result-wide v0
    cmp-long v2, v0, v3
    if-eqz v2, :ok
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
  :ok
    return-void
.end method

# Method lookup uses exact primitive parameter widths. Reflection permits an
# Integer argument to widen to long, so that would not be a refusal control.
.method private static rejectIntSignature()V
    .registers 5
  :try_start
    const-class v0, LIdric/Generated;
    const-string v1, "int64_identity"
    const/4 v2, 1
    new-array v2, v2, [Ljava/lang/Class;
    const/4 v3, 0
    sget-object v4, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;
    aput-object v4, v2, v3
    invoke-virtual {v0, v1, v2}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;
    move-result-object v0
  :try_end
    invoke-static {}, Lqualification/Int64IdentityObserver;->fail()V
    return-void
  :caught
    move-exception v0
    return-void
    .catch Ljava/lang/NoSuchMethodException; {:try_start .. :try_end} :caught
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
    const-wide/high16 v0, -0x8000000000000000L
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    const-wide v0, 0x7fffffffffffffffL
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    const-wide/16 v0, -1
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    const-wide/16 v0, 0
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    const-wide/16 v0, 1
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    const-wide v0, 0x100000001L
    invoke-static {v0, v1}, Lqualification/Int64IdentityObserver;->check(J)V
    invoke-static {}, Lqualification/Int64IdentityObserver;->rejectIntSignature()V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked pure Int64 exports on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
