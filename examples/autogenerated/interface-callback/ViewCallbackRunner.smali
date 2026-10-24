.class public LViewCallbackRunner;
.super Ljava/lang/Object;

# External observer only: it constructs platform objects, dispatches Android's
# real click, and inspects the checked candidate. No candidate action body here.
.method public static main([Ljava/lang/String;)V
    .registers 7

    invoke-static {}, Landroid/os/Looper;->prepareMainLooper()V
    invoke-static {}, Landroid/app/ActivityThread;->systemMain()Landroid/app/ActivityThread;
    move-result-object v0
    invoke-virtual {v0}, Landroid/app/ActivityThread;->getSystemContext()Landroid/app/ContextImpl;
    move-result-object v4

    new-instance v1, Landroid/widget/Button;
    invoke-direct {v1, v4}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    const/16 v2, 101
    invoke-virtual {v1, v2}, Landroid/view/View;->setId(I)V
    new-instance v0, LIdric/Generated;
    invoke-direct {v0}, LIdric/Generated;-><init>()V
    invoke-virtual {v1, v0}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    const-string v2, "\tExact lines\nλ😀\n"
    invoke-static {v1, v2}, LIdric/Generated;->present_text(Landroid/view/View;Ljava/lang/String;)V
    invoke-static {v1}, LIdric/Generated;->read_text(Landroid/view/View;)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure
    invoke-virtual {v1}, Landroid/view/View;->performClick()Z
    move-result v3
    if-eqz v3, :failure
    invoke-static {v1}, LIdric/Generated;->read_text(Landroid/view/View;)Ljava/lang/String;
    move-result-object v2
    const-string v3, "Clicked retained action"
    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure

    # Reusing the same listener must still deliver the actual clicked view.
    new-instance v5, Landroid/widget/Button;
    invoke-direct {v5, v4}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    const/16 v2, 102
    invoke-virtual {v5, v2}, Landroid/view/View;->setId(I)V
    invoke-virtual {v5, v0}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V
    const-string v2, "unchanged"
    invoke-static {v5, v2}, LIdric/Generated;->present_text(Landroid/view/View;Ljava/lang/String;)V
    invoke-virtual {v5}, Landroid/view/View;->performClick()Z
    move-result v3
    if-eqz v3, :failure
    invoke-static {v5}, LIdric/Generated;->read_text(Landroid/view/View;)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v3, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked Idric framework click and exact text"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

    :failure
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL checked Idric framework click and exact text"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 73
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method
