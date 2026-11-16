.class public LActivityFieldRunner;
.super Ljava/lang/Object;

# Independent observer: source exports and actual platform listener dispatch.
# No source algebraic state or IORef logic is reproduced in this file.
.method private static checkpoint(Ljava/lang/String;)V
    .registers 2
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method private static same(Ljava/lang/String;Ljava/lang/String;)V
    .registers 3
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    invoke-static {}, LActivityFieldRunner;->failure()V
  :ok
    return-void
.end method

.method private static failure()V
    .registers 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL private Activity IORef state and receiver isolation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 93
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static observe()V
    .registers 12
    const-string v0, "FIELD stage bootstrap"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    invoke-static {}, Landroid/os/Looper;->prepareMainLooper()V
    invoke-static {}, Landroid/app/ActivityThread;->systemMain()Landroid/app/ActivityThread;
    move-result-object v0
    invoke-virtual {v0}, Landroid/app/ActivityThread;->getSystemContext()Landroid/app/ContextImpl;
    move-result-object v1
    new-instance v2, Landroid/view/View;
    invoke-direct {v2, v1}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    const/16 v6, 101
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    new-instance v3, LIdric/Generated;
    invoke-direct {v3}, LIdric/Generated;-><init>()V
    new-instance v4, LIdric/Generated;
    invoke-direct {v4}, LIdric/Generated;-><init>()V
    const-string v0, "FIELD stage uninitialized"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
  :uninitialized_start
    invoke-static {v3}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v5
  :uninitialized_end
    invoke-static {}, LActivityFieldRunner;->failure()V
    goto :initialized
    .catch Ljava/lang/NullPointerException; {:uninitialized_start .. :uninitialized_end} :uninitialized
  :uninitialized
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;
    move-result-object v0
    const-string v1, "Idriç Activity field 'state' is uninitialized"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
  :initialized
    const-string v0, "FIELD stage initialize two receivers"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    const-string v0, "first λ😀"
    invoke-static {v3, v0}, LIdric/Generated;->initialize_state(Landroid/app/Activity;Ljava/lang/String;)V
    const-string v0, "second"
    invoke-static {v4, v0}, LIdric/Generated;->initialize_state(Landroid/app/Activity;Ljava/lang/String;)V
    invoke-static {v3}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "first λ😀"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v4}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "second"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "FIELD stage real listener dispatch"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    invoke-virtual {v2, v3}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-nez v6, :clicked
    invoke-static {}, LActivityFieldRunner;->failure()V
  :clicked
    invoke-static {v3}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "first λ😀:click"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v4}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "second"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const/16 v6, 102
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-eqz v6, :ignored
    invoke-static {}, LActivityFieldRunner;->failure()V
  :ignored
    const-string v0, "FIELD stage checked resume source export"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    invoke-static {v3}, LIdric/Generated;->resume_state(Landroid/app/Activity;)V
    invoke-static {v3}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "first λ😀:click:resume"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v4}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "second"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "FIELD stage checked destroy source export"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    invoke-static {v3}, LIdric/Generated;->destroy_state(Landroid/app/Activity;)V
    invoke-static {v3}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "closed"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const/16 v6, 101
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-eqz v6, :closed
    invoke-static {}, LActivityFieldRunner;->failure()V
  :closed
    invoke-virtual {v2, v4}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-nez v6, :independent
    invoke-static {}, LActivityFieldRunner;->failure()V
  :independent
    invoke-static {v4}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "second:click"
    invoke-static {v1, v0}, LActivityFieldRunner;->same(Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "FIELD stage wrong receiver"
    invoke-static {v0}, LActivityFieldRunner;->checkpoint(Ljava/lang/String;)V
    new-instance v5, Landroid/app/Activity;
    invoke-direct {v5}, Landroid/app/Activity;-><init>()V
  :wrong_receiver_start
    invoke-static {v5}, LIdric/Generated;->read_state(Landroid/app/Activity;)Ljava/lang/String;
    move-result-object v0
  :wrong_receiver_end
    invoke-static {}, LActivityFieldRunner;->failure()V
    goto :done
    .catch Ljava/lang/ClassCastException; {:wrong_receiver_start .. :wrong_receiver_end} :wrong_receiver
  :wrong_receiver
    move-exception v0
  :done
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS private Activity IORef state and receiver isolation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :observe_start
    invoke-static {}, LActivityFieldRunner;->observe()V
  :observe_end
    return-void
    .catch Ljava/lang/Throwable; {:observe_start .. :observe_end} :unexpected
  :unexpected
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V
    const/16 v1, 94
    invoke-static {v1}, Ljava/lang/System;->exit(I)V
    return-void
.end method
