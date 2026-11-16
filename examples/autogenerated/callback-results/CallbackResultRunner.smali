.class public LCallbackResultRunner;
.super Ljava/lang/Object;

# Independent observer: real View listener dispatch and receiver-local framework
# Intent values. No checked callback implementation lives in this observer.
.method public static main([Ljava/lang/String;)V
    .registers 15
    invoke-static {}, Landroid/os/Looper;->prepareMainLooper()V
    invoke-static {}, Landroid/app/ActivityThread;->systemMain()Landroid/app/ActivityThread;
    move-result-object v0
    invoke-virtual {v0}, Landroid/app/ActivityThread;->getSystemContext()Landroid/app/ContextImpl;
    move-result-object v1
    new-instance v2, Landroid/widget/Button;
    invoke-direct {v2, v1}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    const/16 v6, 101
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    new-instance v3, LIdric/Generated;
    invoke-direct {v3}, LIdric/Generated;-><init>()V
    new-instance v4, LIdric/Generated;
    invoke-direct {v4}, LIdric/Generated;-><init>()V
    new-instance v5, Landroid/content/Intent;
    const-string v6, "permit"
    invoke-direct {v5, v6}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    invoke-virtual {v3, v5}, Landroid/app/Activity;->setIntent(Landroid/content/Intent;)V
    new-instance v5, Landroid/content/Intent;
    const-string v6, "deny"
    invoke-direct {v5, v6}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    invoke-virtual {v4, v5}, Landroid/app/Activity;->setIntent(Landroid/content/Intent;)V

    invoke-virtual {v2, v3}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-eqz v6, :failure
    invoke-virtual {v2, v4}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-nez v6, :failure
    const/16 v6, 102
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    invoke-virtual {v2, v3}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-nez v6, :failure
    const/16 v6, 101
    invoke-virtual {v2, v6}, Landroid/view/View;->setId(I)V
    invoke-virtual {v2}, Landroid/view/View;->performLongClick()Z
    move-result v6
    if-eqz v6, :failure

    new-instance v7, Landroid/view/WindowInsets$Builder;
    invoke-direct {v7}, Landroid/view/WindowInsets$Builder;-><init>()V
    const/4 v9, 1
    const/4 v10, 2
    const/4 v11, 3
    const/4 v12, 4
    invoke-static {v9, v10, v11, v12}, Landroid/graphics/Insets;->of(IIII)Landroid/graphics/Insets;
    move-result-object v8
    invoke-virtual {v7, v8}, Landroid/view/WindowInsets$Builder;->setSystemWindowInsets(Landroid/graphics/Insets;)Landroid/view/WindowInsets$Builder;
    move-result-object v7
    invoke-virtual {v7}, Landroid/view/WindowInsets$Builder;->build()Landroid/view/WindowInsets;
    move-result-object v7
    new-instance v5, Landroid/content/Intent;
    const-string v6, "keep"
    invoke-direct {v5, v6}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    invoke-virtual {v3, v5}, Landroid/app/Activity;->setIntent(Landroid/content/Intent;)V
    new-instance v5, Landroid/content/Intent;
    const-string v6, "consume"
    invoke-direct {v5, v6}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    invoke-virtual {v4, v5}, Landroid/app/Activity;->setIntent(Landroid/content/Intent;)V

    invoke-virtual {v2, v3}, Landroid/view/View;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
    invoke-virtual {v2, v7}, Landroid/view/View;->dispatchApplyWindowInsets(Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
    move-result-object v8
    if-ne v8, v7, :failure
    invoke-virtual {v2, v4}, Landroid/view/View;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
    invoke-virtual {v2, v7}, Landroid/view/View;->dispatchApplyWindowInsets(Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
    move-result-object v8
    if-eq v8, v7, :failure
    invoke-virtual {v8}, Landroid/view/WindowInsets;->getSystemWindowInsetBottom()I
    move-result v6
    if-nez v6, :failure
    invoke-virtual {v7}, Landroid/view/WindowInsets;->getSystemWindowInsetBottom()I
    move-result v6
    const/4 v9, 4
    if-ne v6, v9, :failure
    invoke-virtual {v2, v3}, Landroid/view/View;->setOnApplyWindowInsetsListener(Landroid/view/View$OnApplyWindowInsetsListener;)V
    invoke-virtual {v2, v7}, Landroid/view/View;->dispatchApplyWindowInsets(Landroid/view/WindowInsets;)Landroid/view/WindowInsets;
    move-result-object v8
    if-ne v8, v7, :failure

    sget-object v12, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v13, "PASS checked callback results and actual Activity receivers"
    invoke-virtual {v12, v13}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

  :failure
    sget-object v12, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v13, "FAIL checked callback results and actual Activity receivers"
    invoke-virtual {v12, v13}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v6, 91
    invoke-static {v6}, Ljava/lang/System;->exit(I)V
    return-void
.end method
