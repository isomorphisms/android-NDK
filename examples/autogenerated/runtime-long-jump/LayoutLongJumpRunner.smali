.class public final LIdric/LayoutLongJumpRunner;
.super Ljava/lang/Object;

# External observation only. Every tested indexOf and branch comes from the
# independently compiled checked Idriç candidate on the same classpath.
.method private static assert_flag(Ljava/lang/String;II)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->layout_long_jump(Ljava/lang/String;)I
    move-result v0
    if-eq v0, p1, :pass
    invoke-static {p2}, Ljava/lang/System;->exit(I)V
  :pass
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    const-string v0, ""
    const/4 v1, 0x0
    const/16 v2, 0x71
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "clear"
    const/4 v1, 0x1
    const/16 v2, 0x72
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "needle00"
    const/4 v1, 0x0
    const/16 v2, 0x73
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "needle12"
    const/16 v2, 0x74
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "needle23"
    const/16 v2, 0x75
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "prefixneedle23suffix"
    const/16 v2, 0x76
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    const-string v0, "😀é"
    const/4 v1, 0x1
    const/16 v2, 0x77
    invoke-static {v0, v1, v2}, LIdric/LayoutLongJumpRunner;->assert_flag(Ljava/lang/String;II)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "DEX checked long jump PASS"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
