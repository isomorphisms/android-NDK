.class public final LIdric/BooleanRunner;
.super Ljava/lang/Object;

# External ART oracle for QuickSettingsBoolean.idric. Its candidate has the
# same generated class name as the other fixtures and must run separately.
# No TileService is fabricated to invoke the service-state exports.

.method private static assert_expected(ZZI)V
    .registers 3

    if-eq p0, p1, :pass
    invoke-static {p2}, Ljava/lang/System;->exit(I)V

  :pass
    return-void
.end method

.method private static assert_boxed(IZI)V
    .registers 5

    invoke-static {p0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v0
    invoke-static {v0}, LIdric/Generated;->boxed_is_one(Ljava/lang/Integer;)Z
    move-result v1
    invoke-static {v1, p1, p2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3

    # Exact Boolean constant results, with real Z descriptors.
    invoke-static {}, LIdric/Generated;->boolean_true()Z
    move-result v0
    const/4 v1, 0x1
    const/16 v2, 0x65
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    invoke-static {}, LIdric/Generated;->boolean_false()Z
    move-result v0
    const/4 v1, 0x0
    const/16 v2, 0x66
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V

    # Both dynamic Boolean inputs cross a Z parameter and result boundary.
    const/4 v0, 0x1
    invoke-static {v0}, LIdric/Generated;->boolean_identity(Z)Z
    move-result v0
    const/4 v1, 0x1
    const/16 v2, 0x67
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    const/4 v0, 0x0
    invoke-static {v0}, LIdric/Generated;->boolean_identity(Z)Z
    move-result v0
    const/4 v1, 0x0
    const/16 v2, 0x68
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    const/4 v0, 0x1
    invoke-static {v0}, LIdric/Generated;->boolean_negate(Z)Z
    move-result v0
    const/4 v1, 0x0
    const/16 v2, 0x69
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    const/4 v0, 0x0
    invoke-static {v0}, LIdric/Generated;->boolean_negate(Z)Z
    move-result v0
    const/4 v1, 0x1
    const/16 v2, 0x6a
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V

    # Compare an Int32 to one: two must be false, not coerced to true merely
    # because its raw integer representation is nonzero.
    const/4 v0, 0x1
    invoke-static {v0}, LIdric/Generated;->integer_is_one(I)Z
    move-result v0
    const/4 v1, 0x1
    const/16 v2, 0x6b
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    const/4 v0, 0x0
    invoke-static {v0}, LIdric/Generated;->integer_is_one(I)Z
    move-result v0
    const/4 v1, 0x0
    const/16 v2, 0x6c
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V
    const/4 v0, 0x2
    invoke-static {v0}, LIdric/Generated;->integer_is_one(I)Z
    move-result v0
    const/4 v1, 0x0
    const/16 v2, 0x6d
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_expected(ZZI)V

    # The candidate must unbox real Java Integers and execute its IO result
    # projection. Only boxed one is true.
    const/4 v0, 0x1
    const/4 v1, 0x1
    const/16 v2, 0x6e
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_boxed(IZI)V
    const/4 v0, 0x0
    const/4 v1, 0x0
    const/16 v2, 0x6f
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_boxed(IZI)V
    const/4 v0, 0x2
    const/4 v1, 0x0
    const/16 v2, 0x70
    invoke-static {v0, v1, v2}, LIdric/BooleanRunner;->assert_boxed(IZI)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "DEX Boolean ABI PASS"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
