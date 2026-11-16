.class public LManagedIORefRunner;
.super Ljava/lang/Object;

# Independent scalar observer. The ADT/list/cell implementation is exclusively
# in the checked source candidate; no cell operations are reproduced here.
.method public static main([Ljava/lang/String;)V
    .registers 5
    const-string v0, "λ😀"
    invoke-static {v0}, LIdric/Generated;->ioref_roundtrip(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "updated:λ😀"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure
    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->ioref_roundtrip(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "updated:"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure
    const-string v0, "second call"
    invoke-static {v0}, LIdric/Generated;->ioref_roundtrip(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "updated:second call"
    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :failure
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS managed IORef ADT list Text aliases and independent cells"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
  :failure
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v1, "FAIL managed IORef ADT list Text aliases and independent cells"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 92
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method
