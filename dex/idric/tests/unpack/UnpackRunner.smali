.class public final LIdric/UnpackRunner;
.super Ljava/lang/Object;

# External oracle only: operations call actual source-compiled DEX.
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
    const/4 v1, 0x1
    invoke-static {v0, v1, p2}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 6

    const-string v0, "A"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL record_allowed valid"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->first_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, -1
    const-string v3, "FAIL empty"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "AB"
    invoke-static {v0}, LIdric/Generated;->first_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, 65
    const-string v3, "FAIL ASCII"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋X"
    invoke-static {v0}, LIdric/Generated;->first_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, 129419
    const-string v3, "FAIL supplementary"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "\u0000X"
    invoke-static {v0}, LIdric/Generated;->first_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL NUL"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋X"
    invoke-static {v0}, LIdric/Generated;->second_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, 88
    const-string v3, "FAIL codepoint tail"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋"
    invoke-static {v0}, LIdric/Generated;->second_codepoint(Ljava/lang/String;)I
    move-result v1
    const v2, -1
    const-string v3, "FAIL single codepoint"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->codepoint_count(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL empty count"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "A🦋é"
    invoke-static {v0}, LIdric/Generated;->codepoint_count(Ljava/lang/String;)I
    move-result v1
    const v2, 3
    const-string v3, "FAIL Unicode count"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "é"
    invoke-static {v0}, LIdric/Generated;->codepoint_count(Ljava/lang/String;)I
    move-result v1
    const v2, 2
    const-string v3, "FAIL combining count"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL empty record"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "é🦋漢"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL Unicode record"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "a\u0000b"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL NUL record"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "a\tb"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL tab"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "a\nb"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL LF"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "a\rb"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 0
    const-string v3, "FAIL CR"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "id?value#one"
    invoke-static {v0}, LIdric/Generated;->record_allowed(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL non-address delimiters"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "AZ"
    invoke-static {v0}, LIdric/Generated;->alias_preserved(Ljava/lang/String;)I
    move-result v1
    const v2, 65
    const-string v3, "FAIL independent alias"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋é"
    invoke-static {v0}, LIdric/Generated;->alias_preserved(Ljava/lang/String;)I
    move-result v1
    const v2, 129419
    const-string v3, "FAIL independent Unicode alias"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->integer_wrap(Ljava/lang/String;)I
    move-result v1
    const v2, 2147483647
    const-string v3, "FAIL negative Integer cast"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "x"
    invoke-static {v0}, LIdric/Generated;->integer_wrap(Ljava/lang/String;)I
    move-result v1
    const v2, 1
    const-string v3, "FAIL positive Integer cast"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_integer(IILjava/lang/String;)V

    const-string v0, "🦋\u0000é漢"
    invoke-static {v0}, LIdric/Generated;->roundtrip(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "🦋\u0000é漢"
    const-string v3, "FAIL roundtrip"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->roundtrip(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, ""
    const-string v3, "FAIL roundtrip"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "🦋X"
    invoke-static {v0}, LIdric/Generated;->tail_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "X"
    const-string v3, "FAIL tail_text"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "🦋"
    invoke-static {v0}, LIdric/Generated;->tail_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, ""
    const-string v3, "FAIL tail_text"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->tail_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, ""
    const-string v3, "FAIL tail_text"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "\u0000X"
    invoke-static {v0}, LIdric/Generated;->tail_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "X"
    const-string v3, "FAIL tail_text"
    invoke-static {v1, v2, v3}, LIdric/UnpackRunner;->assert_text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked Idric unpack on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
