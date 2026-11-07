.class public LReaderChecks;
.super Ljava/lang/Object;

# Independent observation in a real registered Android application process.
.method public static check(Landroid/content/Context;)Ljava/lang/String;
    .registers 10
    move-object v0, p0
    const-string v3, "Constructed reader text"
    invoke-static {v0, v3}, LIdric/Generated;->create_reader_view(Landroid/content/Context;Ljava/lang/String;)Landroid/widget/TextView;
    move-result-object v1
    sget-object v3, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v4, "STAGE framework TextView constructed"
    invoke-virtual {v3, v4}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V

    # Begin with unsuitable platform state so omissions cannot pass by default.
    const/4 v0, 1
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setSingleLine(Z)V
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setHorizontallyScrolling(Z)V
    const/4 v0, 0
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setTextIsSelectable(Z)V

    const-string v2, "\tExact retained text λ😀\n\nReading preserves the source while Android wraps this deliberately long paragraph against the parent width. Reading preserves the source while Android wraps this deliberately long paragraph against the parent width. Reading preserves the source while Android wraps this deliberately long paragraph against the parent width.\n  trailing spaces  \n"
    invoke-static {v1, v2}, LIdric/Generated;->reader_text(Landroid/widget/TextView;Ljava/lang/String;)V
    invoke-static {v1}, LIdric/Generated;->read_reader_text(Landroid/widget/TextView;)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :exact_failure
    invoke-virtual {v1}, Landroid/widget/TextView;->isTextSelectable()Z
    move-result v0
    if-eqz v0, :selection_failure

    # Replace the same view with empty text; stale display must not survive.
    const-string v3, ""
    invoke-static {v1, v3}, LIdric/Generated;->reader_text(Landroid/widget/TextView;Ljava/lang/String;)V
    invoke-static {v1}, LIdric/Generated;->read_reader_text(Landroid/widget/TextView;)Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :exact_failure
    invoke-static {v1, v2}, LIdric/Generated;->reader_text(Landroid/widget/TextView;Ljava/lang/String;)V

    # EXACTLY 240 physical pixels versus EXACTLY 720. These are observer widths,
    # not product dimensions, font assumptions, or IB code-point coordinates.
    const v3, 0x400000f0
    const/4 v4, 0
    invoke-virtual {v1, v3, v4}, Landroid/view/View;->measure(II)V
    invoke-virtual {v1}, Landroid/widget/TextView;->getLineCount()I
    move-result v5
    const v3, 0x400002d0
    invoke-virtual {v1, v3, v4}, Landroid/view/View;->measure(II)V
    invoke-virtual {v1}, Landroid/widget/TextView;->getLineCount()I
    move-result v6
    if-le v5, v6, :reflow_failure
    invoke-static {v1}, LIdric/Generated;->read_reader_text(Landroid/widget/TextView;)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :exact_failure

    const-string v1, "PASS checked TextView construction, exact native text, selection, empty replacement and width reflow"
    return-object v1

    :exact_failure
    const-string v1, "FAIL exact native reader text"
    goto :failure
    :selection_failure
    const-string v1, "FAIL native reader selection"
    goto :failure
    :reflow_failure
    const-string v1, "FAIL native reader width reflow"
    :failure
    return-object v1
.end method
