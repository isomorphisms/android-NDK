.class public final LIdric/InvokeRangeRunner;
.super Ljava/lang/Object;

# External ART oracle for DexInvokeRange.idric. It belongs on a classpath with
# that candidate alone; the other fixture candidates also use LIdric/Generated;.
# Only the checked candidate calls String.regionMatches under test.

.method private static assert_expected(III)V
    .registers 3

    if-eq p0, p1, :pass
    invoke-static {p2}, Ljava/lang/System;->exit(I)V

  :pass
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 9

    # Six candidate arguments: source, ignore_case, source_offset, other,
    # other_offset, count. Unequal offsets and count expose argument swaps.
    const-string v0, "prefixAbCtail"
    const/4 v1, 0x1
    const/4 v2, 0x6
    const-string v3, "__aBc?"
    const/4 v4, 0x2
    const/4 v5, 0x3
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x1
    const/16 v8, 0x5b
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    # The same region differs when matching becomes case sensitive.
    const/4 v1, 0x0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x5c
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    # Matching exact case succeeds; including the next character does not.
    const-string v3, "__AbC?"
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x1
    const/16 v8, 0x5d
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V
    const/4 v5, 0x4
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x5e
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    # Shift each offset independently. Neither shifted region matches.
    const/4 v5, 0x3
    const/4 v2, 0x7
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x5f
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V
    const/4 v2, 0x6
    const/4 v4, 0x3
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x60
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    # A zero-length region at both valid ends succeeds. A negative source
    # offset fails without turning the boolean result into a default success.
    const/16 v2, 0xd
    const/4 v4, 0x6
    const/4 v5, 0x0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x1
    const/16 v8, 0x61
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V
    const/4 v2, -0x1
    const/4 v4, 0x2
    const/4 v5, 0x3
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match(Ljava/lang/String;IILjava/lang/String;II)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x62
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    # This export deliberately receives a different order: source,
    # source_offset, other, count, other_offset, ignore_case. The candidate
    # must stage the correct virtual receiver/arguments before its range call.
    const-string v0, "prefixAbCtail"
    const/4 v1, 0x6
    const-string v2, "__aBc?"
    const/4 v3, 0x3
    const/4 v4, 0x2
    const/4 v5, 0x1
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match_reordered(Ljava/lang/String;ILjava/lang/String;III)I
    move-result v6
    const/4 v7, 0x1
    const/16 v8, 0x63
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V
    const/4 v5, 0x0
    invoke-static/range {v0 .. v5}, LIdric/Generated;->region_match_reordered(Ljava/lang/String;ILjava/lang/String;III)I
    move-result v6
    const/4 v7, 0x0
    const/16 v8, 0x64
    invoke-static {v6, v7, v8}, LIdric/InvokeRangeRunner;->assert_expected(III)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "DEX invoke range PASS"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
