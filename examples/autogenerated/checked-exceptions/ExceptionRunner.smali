.class public LExceptionRunner;
.super Ljava/lang/Object;

.method public static main([Ljava/lang/String;)V
    .registers 3
  :observe_start
    invoke-static {}, LExceptionRunner;->observe()V
  :observe_end
    .catch Ljava/lang/AssertionError; {:observe_start .. :observe_end} :assertion
    .catch Ljava/lang/Throwable; {:observe_start .. :observe_end} :unexpected
    return-void
  :assertion
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const/16 v0, 95
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
  :unexpected
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const/16 v0, 96
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static checkScenario(ILjava/lang/String;)V
    .registers 5
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-static {v0, p0}, LIdric/Generated;->exercise_checked_exceptions(Ljava/lang/StringBuilder;I)Ljava/lang/String;
    move-result-object v1
    invoke-virtual {p1, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v2
    if-eqz v2, :failed
    return-void
  :failed
    new-instance v0, Ljava/lang/AssertionError;
    const-string v1, "checked exception action, handler or cleanup order changed"
    invoke-direct {v0, v1}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v0
.end method

.method private static observe()V
    .registers 4
    const/4 v0, 0
    const-string v1, "normal|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 1
    const-string v1, "caught:original|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 2
    const-string v1, "cleanup|caught:original|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 3
    const-string v1, "normal|cleanup|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 4
    const-string v1, "caught:cleanup|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 5
    const-string v1, "caught:handler|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V
    const/4 v0, 6
    const-string v1, "normal|caught:cleanup|"
    invoke-static {v0, v1}, LExceptionRunner;->checkScenario(ILjava/lang/String;)V

    new-instance v0, Ljava/lang/IllegalArgumentException;
    const-string v1, "observer-owned identity"
    invoke-direct {v0, v1}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V
  :rethrow_start
    invoke-static {v0}, LIdric/Generated;->rethrow_checked_reference(Ljava/lang/Throwable;)V
  :rethrow_end
    .catch Ljava/lang/Throwable; {:rethrow_start .. :rethrow_end} :rethrown
    new-instance v1, Ljava/lang/AssertionError;
    const-string v2, "checked rethrow returned"
    invoke-direct {v1, v2}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v1
  :rethrown
    move-exception v1
    if-eq v0, v1, :passed
    new-instance v1, Ljava/lang/AssertionError;
    const-string v2, "checked rethrow replaced actual Throwable reference"
    invoke-direct {v1, v2}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v1
  :passed
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked exception action, actual Throwable identity and exactly-once cleanup"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
