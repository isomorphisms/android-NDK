.class public LReferenceNullRunner;
.super Ljava/lang/Object;

# Independent observer: passes actual nulls and platform objects to source
# exports. No candidate-producing bytecode or substitute null test is here.
.method private static equal(Ljava/lang/String;II)V
    .registers 5
    if-eq p1, p2, :same
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const-string v1, "FAIL checked reference-null semantics"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 95
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :same
    return-void
.end method

.method private static observe()V
    .registers 7
    const/4 v0, 0x0
    const/4 v2, 0x1
    invoke-static {v0}, LIdric/Generated;->object_null(Ljava/lang/Object;)I
    move-result v1
    const-string v3, "object null"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    new-instance v0, Ljava/lang/Object;
    invoke-direct {v0}, Ljava/lang/Object;-><init>()V
    const/4 v2, 0x0
    invoke-static {v0}, LIdric/Generated;->object_null(Ljava/lang/Object;)I
    move-result v1
    const-string v3, "object nonnull"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V

    const/4 v0, 0x0
    const/4 v2, 0x1
    invoke-static {v0}, LIdric/Generated;->key_event_null(Landroid/view/KeyEvent;)I
    move-result v1
    const-string v3, "KeyEvent null"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    new-instance v0, Landroid/view/KeyEvent;
    const/4 v4, 0x0
    const/16 v5, 66
    invoke-direct {v0, v4, v5}, Landroid/view/KeyEvent;-><init>(II)V
    const/4 v2, 0x0
    invoke-static {v0}, LIdric/Generated;->key_event_null(Landroid/view/KeyEvent;)I
    move-result v1
    const-string v3, "KeyEvent nonnull"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V

    const/4 v0, 0x0
    const/4 v2, 0x1
    invoke-static {v0}, LIdric/Generated;->intent_null(Landroid/content/Intent;)I
    move-result v1
    const-string v3, "Intent null"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    new-instance v0, Landroid/content/Intent;
    const-string v4, "android.intent.action.CREATE_DOCUMENT"
    invoke-direct {v0, v4}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    const/4 v2, 0x0
    invoke-static {v0}, LIdric/Generated;->intent_null(Landroid/content/Intent;)I
    move-result v1
    const-string v3, "Intent nonnull"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V

    const/4 v0, 0x0
    const/4 v2, 0x1
    invoke-static {v0}, LIdric/Generated;->uri_null(Landroid/net/Uri;)I
    move-result v1
    const-string v3, "Uri null"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    const-string v4, "content://reference-null/visible"
    invoke-static {v4}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
    move-result-object v0
    const/4 v2, 0x0
    invoke-static {v0}, LIdric/Generated;->uri_null(Landroid/net/Uri;)I
    move-result v1
    const-string v3, "Uri nonnull"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V

    const/4 v0, 0x0
    const/4 v2, 0x1
    invoke-static {v0}, LIdric/Generated;->stream_null(Ljava/io/OutputStream;)I
    move-result v1
    const-string v3, "OutputStream null"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    new-instance v0, Ljava/io/ByteArrayOutputStream;
    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V
    const/4 v2, 0x0
    invoke-static {v0}, LIdric/Generated;->stream_null(Ljava/io/OutputStream;)I
    move-result v1
    const-string v3, "OutputStream nonnull"
    invoke-static {v3, v1, v2}, LReferenceNullRunner;->equal(Ljava/lang/String;II)V
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->close()V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked reference-null semantics"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :observe_start
    invoke-static {}, LReferenceNullRunner;->observe()V
  :observe_end
    return-void
    .catch Ljava/lang/Throwable; {:observe_start .. :observe_end} :unexpected
  :unexpected
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V
    const/16 v1, 96
    invoke-static {v1}, Ljava/lang/System;->exit(I)V
    return-void
.end method
