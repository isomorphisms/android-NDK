.class public final LIdric/IBUnpackRunner;
.super Ljava/lang/Object;

# Unchanged IB.LongViewAndroid is the candidate; this is only an external caller.
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

.method public static main([Ljava/lang/String;)V
    .registers 9
    const-string v0, "task"
    const-string v1, "tab"
    const-string v2, "nav"
    const-string v3, "host-a"
    const-string v4, "host-a"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, 1
    const-string v7, "FAIL actual IB same host"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v4, "host-b"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, 2
    const-string v7, "FAIL actual IB changed host"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "task\tbad"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, -1
    const-string v7, "FAIL actual IB invalid task"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "task"
    const-string v1, "tab\nbad"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, -1
    const-string v7, "FAIL actual IB invalid tab"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v1, "tab"
    const-string v2, "nav\rbad"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, -1
    const-string v7, "FAIL actual IB invalid navigation"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v2, "nav"
    const-string v3, ""
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, -1
    const-string v7, "FAIL actual IB empty prior host"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v3, "host-a"
    const-string v4, ""
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, -1
    const-string v7, "FAIL actual IB empty next host"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋"
    const-string v1, "漢"
    const-string v2, "é"
    const-string v3, "same🦋"
    const-string v4, "same🦋"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, 1
    const-string v7, "FAIL actual IB Unicode"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "task?ok"
    const-string v1, "tab#ok"
    const-string v2, "nav"
    const-string v3, "A"
    const-string v4, "B"
    invoke-static/range {v0 .. v4}, LIdric/Generated;->longview_host_generation(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v5
    const v6, 2
    const-string v7, "FAIL actual IB identity delimiters"
    invoke-static {v5, v6, v7}, LIdric/IBUnpackRunner;->assert_integer(IILjava/lang/String;)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS actual IB LongViewAndroid on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
