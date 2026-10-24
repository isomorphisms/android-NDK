.class public LIdric/ReaderInstrumentation;
.super Landroid/app/Instrumentation;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Instrumentation;-><init>()V
    return-void
.end method

# onCreate executes after normal target Application binding on the main thread.
# Android owns UID, provider registration, font initialization and real Context.
.method public onCreate(Landroid/os/Bundle;)V
    .registers 7
    invoke-super {p0, p1}, Landroid/app/Instrumentation;->onCreate(Landroid/os/Bundle;)V
    invoke-virtual {p0}, Landroid/app/Instrumentation;->getTargetContext()Landroid/content/Context;
    move-result-object v0
    invoke-static {v0}, LReaderChecks;->check(Landroid/content/Context;)Ljava/lang/String;
    move-result-object v1
    new-instance v2, Landroid/os/Bundle;
    invoke-direct {v2}, Landroid/os/Bundle;-><init>()V
    const-string v3, "stream"
    invoke-virtual {v2, v3, v1}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V
    const-string v3, "PASS "
    invoke-virtual {v1, v3}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v4
    if-eqz v4, :failed
    const/4 v4, 0
    goto :finish
    :failed
    const/16 v4, 73
    :finish
    invoke-virtual {p0, v4, v2}, Landroid/app/Instrumentation;->finish(ILandroid/os/Bundle;)V
    return-void
.end method
