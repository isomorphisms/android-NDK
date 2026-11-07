.class public final LIdric/LoopValueRunner;
.super Ljava/lang/Object;

# Independent oracle: invokes only the actual source-compiled candidate.
.method private static assert_integer(IILjava/lang/String;)V
    .registers 5
    if-eq p0, p1, :pass
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :pass
    return-void
.end method

.method private static assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 5
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    const/4 v1, 1
    invoke-static {v0, v1, p2}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 6

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->contains_linefeed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL empty"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "abc"
    invoke-static {v0}, LIdric/Generated;->contains_linefeed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL ordinary"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "ab\ncd"
    invoke-static {v0}, LIdric/Generated;->contains_linefeed(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL linefeed"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "λ𝄞z"
    invoke-static {v0}, LIdric/Generated;->contains_linefeed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL supplementary not linefeed"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "λ𝄞z"
    invoke-static {v0}, LIdric/Generated;->contains_music_symbol(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL supplementary found"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "𝄢"
    invoke-static {v0}, LIdric/Generated;->contains_music_symbol(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL different supplementary"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "ordinary"
    invoke-static {v0}, LIdric/Generated;->source_marker(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "fallback λ𝄞"
    const-string v3, "FAIL Unicode fallback"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "prefix!"
    invoke-static {v0}, LIdric/Generated;->source_marker(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "found"
    const-string v3, "FAIL marker"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "ordinary"
    invoke-static {v0}, LIdric/Generated;->saw_marker(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL false flag"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "!suffix"
    invoke-static {v0}, LIdric/Generated;->saw_marker(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL true flag"
    invoke-static {v1, v2, v3}, LIdric/LoopValueRunner;->assert_integer(IILjava/lang/String;)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked source loop values on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
