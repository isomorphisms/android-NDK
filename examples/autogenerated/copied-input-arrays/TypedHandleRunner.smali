.class public Lqualification/TypedHandleRunner;
.super Ljava/lang/Object;

# Calls the real imported producer and independently checks the scalar handle
# boundary. All C allocation/copy/release operations remain in the same fixture.
.method private static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked typed scalar handles"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static check(ILjava/lang/String;)V
    .registers 7
    invoke-static {p0}, LIdric/Generated;->typed_handle_bits(I)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :released
    invoke-static {}, Lqualification/TypedHandleRunner;->fail()V
  :released
    invoke-static {}, LIdric/Generated;->lastHandle()J
    move-result-wide v0
    const-wide/16 v2, 0
    cmp-long v4, v0, v2
    if-eqz v4, :ok
    invoke-static {}, Lqualification/TypedHandleRunner;->fail()V
  :ok
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const v0, 0x1000001
    const-string v1, "4170000010000000:4"
    invoke-static {v0, v1}, Lqualification/TypedHandleRunner;->check(ILjava/lang/String;)V
    const/4 v0, -1
    const-string v1, "bff0000000000000:4"
    invoke-static {v0, v1}, Lqualification/TypedHandleRunner;->check(ILjava/lang/String;)V
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v0
    const-wide/16 v2, 2
    cmp-long v0, v0, v2
    if-eqz v0, :ok
    invoke-static {}, Lqualification/TypedHandleRunner;->fail()V
  :ok
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked typed scalar handles on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
