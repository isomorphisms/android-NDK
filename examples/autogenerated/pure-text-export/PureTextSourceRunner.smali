.class public final LIdric/PureTextSourceRunner;
.super Ljava/lang/Object;

# Independent caller: supplies no target parser or expected implementation.
.method private static assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 6
    invoke-static {p0}, LIdric/Generated;->source_title(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :pass
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :pass
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    const-string v0, ""
    const-string v1, ""
    const-string v2, "FAIL actual IB empty title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "<html><head><title>One document</title></head><body><p>body</p></body></html>"
    const-string v1, "One document"
    const-string v2, "FAIL actual IB ordinary title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "<html><title>Recovered</title><p>unterminated body"
    const-string v1, "Recovered"
    const-string v2, "FAIL actual IB malformed title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "<title>café 🦉 漢</title>"
    const-string v1, "café 🦉 漢"
    const-string v2, "FAIL actual IB Unicode title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    # Reuse the same loaded pure method with a different result, then empty.
    const-string v0, "<title>Second document</title>"
    const-string v1, "Second document"
    const-string v2, "FAIL actual IB repeated title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, "<p>No title</p>"
    const-string v1, ""
    const-string v2, "FAIL actual IB stale title"
    invoke-static {v0, v1, v2}, LIdric/PureTextSourceRunner;->assert_title(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS unchanged IB pure Text source projection on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
