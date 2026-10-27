.class public final Lacceptance/ManagedExportObserver;
.super Ljava/lang/Object;

# Oracle only: all application work stays in the source-generated candidate.
.method private static require(ZLjava/lang/String;)V
    .registers 3
    if-nez p0, :passed
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :passed
    return-void
.end method

.method private static text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    invoke-static {v0, p2}, Lacceptance/ManagedExportObserver;->require(ZLjava/lang/String;)V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 5
    const-string v0, "λ𝄞z"
    invoke-static {v0}, LIdric/Generated;->reverse_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "z𝄞λ"
    const-string v3, "FAIL Unicode list/record export"
    invoke-static {v1, v2, v3}, Lacceptance/ManagedExportObserver;->text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->reverse_text(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v3, "FAIL empty list export"
    invoke-static {v1, v0, v3}, Lacceptance/ManagedExportObserver;->text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    const v0, 2147483647
    invoke-static {v0}, LIdric/Generated;->retained_integer(I)I
    move-result v1
    const v2, -2147483642
    const/4 v0, 0
    if-ne v1, v2, :integer_checked
    const/4 v0, 1
  :integer_checked
    const-string v3, "FAIL Int32 width at managed export"
    invoke-static {v0, v3}, Lacceptance/ManagedExportObserver;->require(ZLjava/lang/String;)V
    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->has_text(Ljava/lang/String;)Z
    move-result v1
    xor-int/lit8 v1, v1, 1
    const-string v3, "FAIL false Boolean export"
    invoke-static {v1, v3}, Lacceptance/ManagedExportObserver;->require(ZLjava/lang/String;)V
    const-string v0, "λ"
    invoke-static {v0}, LIdric/Generated;->has_text(Ljava/lang/String;)Z
    move-result v1
    const-string v3, "FAIL true Boolean export"
    invoke-static {v1, v3}, Lacceptance/ManagedExportObserver;->require(ZLjava/lang/String;)V
    const-string v0, "λ𝄞z"
    invoke-static {v0}, LIdric/Generated;->read_then_reverse(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "z𝄞λ"
    const-string v3, "FAIL framework IO to checked list helper"
    invoke-static {v1, v2, v3}, Lacceptance/ManagedExportObserver;->text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    const-string v0, ""
    invoke-static {v0}, LIdric/Generated;->read_then_reverse(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v1
    const-string v2, "empty"
    const-string v3, "FAIL framework empty result"
    invoke-static {v1, v2, v3}, Lacceptance/ManagedExportObserver;->text(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked managed exports on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
