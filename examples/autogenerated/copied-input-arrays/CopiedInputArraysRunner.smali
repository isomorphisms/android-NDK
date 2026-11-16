.class public Lqualification/CopiedInputArraysRunner;
.super Ljava/lang/Object;

# This observer contains independent constants and calls the source-produced
# DEX. It never supplies an implementation of its record/list/array producer.
.method private static fail()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked copied input arrays"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static rejectReleased(J)V
    .registers 3
  :try_start
    invoke-static {p0, p1}, LIdric/Generated;->coefficientCount(J)I
    move-result v0
  :try_end
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
  :caught
    move-exception v0
    return-void
    .catch Ljava/lang/IllegalArgumentException; {:try_start .. :try_end} :caught
.end method

.method private static equalLong(JJ)V
    .registers 5
    cmp-long v0, p0, p2
    if-eqz v0, :ok
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
  :ok
    return-void
.end method

.method private static coefficients()[D
    .registers 2
    const/4 v0, 4
    new-array v0, v0, [D
    fill-array-data v0, :values
    return-object v0
  :values
    .array-data 8
        0x4170000010000000L
        -0x8000000000000000L
        0x3fd999999999999aL
        0x7ff8000000000000L
    .end array-data
.end method

.method private static exponents()[I
    .registers 2
    const/16 v0, 12
    new-array v0, v0, [I
    fill-array-data v0, :values
    return-object v0
  :values
    .array-data 4
        2
        0
        0
        0
        1
        0
        0
        0
        1
        0
        0
        0
    .end array-data
.end method

.method private static copy(I[D[I)J
    .registers 12
    const/4 v0, 1
    const/4 v1, 2
    const/4 v2, 0
    const/4 v3, 1
    const/4 v4, 2
    const/4 v5, 3
    const/4 v6, 4
    if-nez p0, :not_version
    const/4 v0, 2
  :not_version
    const/4 v7, 1
    if-ne p0, v7, :not_offsets
    const/4 v4, 0
  :not_offsets
    const/4 v7, 2
    if-ne p0, v7, :not_end
    const/4 v6, 3
  :not_end
    const/4 v7, 3
    if-ne p0, v7, :not_degree
    const/4 v1, 1
  :not_degree
    move-object v7, p1
    move-object v8, p2
    invoke-static/range {v0 .. v8}, LIdric/Generated;->copySurface(IIIIIII[D[I)J
    move-result-wide v0
    return-wide v0
.end method

.method private static rejectShape(I[D[I)V
    .registers 5
  :try_start
    invoke-static {p0, p1, p2}, Lqualification/CopiedInputArraysRunner;->copy(I[D[I)J
    move-result-wide v0
  :try_end
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
  :caught
    move-exception v0
    return-void
    .catch Ljava/lang/IllegalArgumentException; {:try_start .. :try_end} :caught
.end method

.method private static checkSnapshot(J)V
    .registers 10
    invoke-static {p0, p1}, LIdric/Generated;->coefficientCount(J)I
    move-result v0
    const/4 v1, 4
    if-ne v0, v1, :failed
    const/4 v2, 0
    invoke-static {p0, p1, v2}, LIdric/Generated;->coefficientBits(JI)J
    move-result-wide v0
    const-wide v2, 0x4170000010000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    const/4 v2, 1
    invoke-static {p0, p1, v2}, LIdric/Generated;->coefficientBits(JI)J
    move-result-wide v0
    const-wide v2, -0x8000000000000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    const/4 v2, 2
    invoke-static {p0, p1, v2}, LIdric/Generated;->coefficientBits(JI)J
    move-result-wide v0
    const-wide v2, 0x3fd999999999999aL
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    const/4 v2, 3
    invoke-static {p0, p1, v2}, LIdric/Generated;->coefficientBits(JI)J
    move-result-wide v0
    const-wide v2, 0x7ff8000000000000L
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    const/4 v2, 0
    invoke-static {p0, p1, v2}, LIdric/Generated;->exponentAt(JI)I
    move-result v0
    const/4 v1, 2
    if-ne v0, v1, :failed
    const/16 v2, 11
    invoke-static {p0, p1, v2}, LIdric/Generated;->exponentAt(JI)I
    move-result v0
    if-eqz v0, :ok
  :failed
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
  :ok
    return-void
.end method

.method private static rejectNull([D[I)V
    .registers 5
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v0
  :try_start
    invoke-static {p0, p1}, LIdric/Generated;->copy_arrays([D[I)I
    move-result v2
  :try_end
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
  :caught
    move-exception v2
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v2
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    return-void
    .catch Ljava/lang/NullPointerException; {:try_start .. :try_end} :caught
.end method

.method private static rejectNativeNull([D[I)V
    .registers 5
    const/4 v0, 4
  :try_start
    invoke-static {v0, p0, p1}, Lqualification/CopiedInputArraysRunner;->copy(I[D[I)J
    move-result-wide v0
  :try_end
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
  :caught
    move-exception v0
    return-void
    .catch Ljava/lang/NullPointerException; {:try_start .. :try_end} :caught
.end method

# Reflection supplies an incompatible float[] without ART-invalid bytecode.
# The reflected public descriptor must reject it before native entry.
.method private static rejectType([I)V
    .registers 11
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v0
    const-class v2, LIdric/Generated;
    const-string v3, "copy_arrays"
    const/4 v4, 2
    new-array v4, v4, [Ljava/lang/Class;
    const/4 v5, 0
    const-class v6, [D
    aput-object v6, v4, v5
    const/4 v5, 1
    const-class v6, [I
    aput-object v6, v4, v5
    invoke-virtual {v2, v3, v4}, Ljava/lang/Class;->getDeclaredMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;
    move-result-object v2
    const/4 v3, 2
    new-array v3, v3, [Ljava/lang/Object;
    const/4 v4, 4
    new-array v4, v4, [F
    const/4 v5, 0
    aput-object v4, v3, v5
    const/4 v5, 1
    aput-object p0, v3, v5
    const/4 v4, 0
  :try_start
    invoke-virtual {v2, v4, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v2
  :try_end
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
  :caught
    move-exception v2
    invoke-static {}, LIdric/Generated;->entryCount()J
    move-result-wide v2
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V
    return-void
    .catch Ljava/lang/IllegalArgumentException; {:try_start .. :try_end} :caught
.end method

.method public static main([Ljava/lang/String;)V
    .registers 10
    const v0, 0x1000001
    invoke-static {v0}, LIdric/Generated;->produce_surface(I)I
    move-result v0
    const/4 v1, 4
    if-ne v0, v1, :failed
    invoke-static {}, LIdric/Generated;->lastHandle()J
    move-result-wide v0
    invoke-static {v0, v1}, Lqualification/CopiedInputArraysRunner;->checkSnapshot(J)V
    invoke-static {v0, v1}, LIdric/Generated;->releaseSurface(J)V
    invoke-static {v0, v1}, Lqualification/CopiedInputArraysRunner;->rejectReleased(J)V

    invoke-static {}, Lqualification/CopiedInputArraysRunner;->coefficients()[D
    move-result-object v4
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->exponents()[I
    move-result-object v5
    const/4 v3, 4
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->copy(I[D[I)J
    move-result-wide v0
    const/4 v2, 0
    const-wide/16 v6, 0
    aput-wide v6, v4, v2
    const/4 v6, 0
    aput v6, v5, v2
    invoke-static {v0, v1}, Lqualification/CopiedInputArraysRunner;->checkSnapshot(J)V
    invoke-static {v0, v1}, LIdric/Generated;->releaseSurface(J)V

    invoke-static {}, Lqualification/CopiedInputArraysRunner;->coefficients()[D
    move-result-object v4
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->exponents()[I
    move-result-object v5
    const/4 v3, 0
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/4 v3, 1
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/4 v3, 2
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/4 v3, 3
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/16 v3, 11
    new-array v6, v3, [I
    const/4 v3, 4
    invoke-static {v3, v4, v6}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/4 v2, 0
    const/4 v3, -1
    aput v3, v5, v2
    const/4 v3, 4
    invoke-static {v3, v4, v5}, Lqualification/CopiedInputArraysRunner;->rejectShape(I[D[I)V
    const/4 v2, 0
    invoke-static {v2, v5}, Lqualification/CopiedInputArraysRunner;->rejectNull([D[I)V
    invoke-static {v4, v2}, Lqualification/CopiedInputArraysRunner;->rejectNull([D[I)V
    invoke-static {v5}, Lqualification/CopiedInputArraysRunner;->rejectType([I)V
    const/4 v2, 0
    invoke-static {v2, v5}, Lqualification/CopiedInputArraysRunner;->rejectNativeNull([D[I)V
    invoke-static {v4, v2}, Lqualification/CopiedInputArraysRunner;->rejectNativeNull([D[I)V
    invoke-static {}, LIdric/Generated;->lastHandle()J
    move-result-wide v0
    const-wide/16 v2, 0
    invoke-static {v0, v1, v2, v3}, Lqualification/CopiedInputArraysRunner;->equalLong(JJ)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked copied input arrays on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
  :failed
    invoke-static {}, Lqualification/CopiedInputArraysRunner;->fail()V
    return-void
.end method
