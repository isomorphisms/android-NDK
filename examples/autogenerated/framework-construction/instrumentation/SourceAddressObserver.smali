.class public LIdric/SourceAddressObserver;
.super Landroid/app/Activity;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

# Independent receiver only. It reports the actual external intent delivered
# by Android; it never constructs or substitutes the IB reading screen.
.method public onCreate(Landroid/os/Bundle;)V
    .registers 6
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/Intent;->getAction()Ljava/lang/String;
    move-result-object v1
    const-string v2, "android.intent.action.VIEW"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failed
    invoke-virtual {v0}, Landroid/content/Intent;->getDataString()Ljava/lang/String;
    move-result-object v1
    const-string v2, "https://github.com/isomorphisms/ib/blob/9027d5ea0ce8718b0337b4cd3d16c0549dc2b2ed/README.md"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failed
    const-string v1, "PASS exact native source address"
    goto :report
    :failed
    const-string v1, "FAIL native source address"
    :report
    new-instance v0, Landroid/widget/TextView;
    invoke-direct {v0, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
    return-void
.end method
