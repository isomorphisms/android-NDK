.class public final LIdric/QuickSettingsRunner;
.super Ljava/lang/Object;

# External ART oracle only. Integer construction belongs to this runner;
# Both result observations execute in the separately supplied candidate DEX.
# No Tile object, TileService, registration, or addition request is fabricated.

.method private static assert_result(III)V
    .registers 6

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->callback_result_code(Ljava/lang/Integer;)I
    move-result v1
    if-eq v1, p0, :check_tag

    # p1 identifies the failed case. A wrong result must end the process.
    invoke-static {p1}, Ljava/lang/System;->exit(I)V

  :check_tag
    invoke-static {v0}, LIdric/Generated;->callback_result_tag(Ljava/lang/Integer;)I
    move-result v1
    if-eq v1, p2, :pass

    # Tag failures use the raw-code case exit plus 60: exits 121-134.
    const/16 v2, 0x3c
    add-int v2, p1, v2
    invoke-static {v2}, Ljava/lang/System;->exit(I)V

  :pass
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3

    # Ordinary results: not added, already added, added. Failure exits 61-63.
    const/4 v0, 0x0
    const/16 v1, 0x3d
    const/16 v2, 0x0
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/4 v0, 0x1
    const/16 v1, 0x3e
    const/16 v2, 0x1
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/4 v0, 0x2
    const/16 v1, 0x3f
    const/16 v2, 0x2
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V

    # API 33 errors 1000-1005. Failure exits 64-69.
    const/16 v0, 0x3e8
    const/16 v1, 0x40
    const/16 v2, 0x3
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3e9
    const/16 v1, 0x41
    const/16 v2, 0x4
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3ea
    const/16 v1, 0x42
    const/16 v2, 0x5
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3eb
    const/16 v1, 0x43
    const/16 v2, 0x6
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3ec
    const/16 v1, 0x44
    const/16 v2, 0x7
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3ed
    const/16 v1, 0x45
    const/16 v2, 0x8
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V

    # Unknown values 3, 1006, -1, Int32 minimum/maximum must survive unchanged.
    # Failure exits 70-74 distinguish these from known-result failures.
    const/4 v0, 0x3
    const/16 v1, 0x46
    const/16 v2, 0x9
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/16 v0, 0x3ee
    const/16 v1, 0x47
    const/16 v2, 0x9
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const/4 v0, -0x1
    const/16 v1, 0x48
    const/16 v2, 0x9
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const v0, -0x80000000
    const/16 v1, 0x49
    const/16 v2, 0x9
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V
    const v0, 0x7fffffff
    const/16 v1, 0x4a
    const/16 v2, 0x9
    invoke-static {v0, v1, v2}, LIdric/QuickSettingsRunner;->assert_result(III)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "quick-settings callback payload PASS"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
