.class public final Lacceptance/SearchExportObserver;
.super Ljava/lang/Object;

.method private static expect(Landroid/content/Intent;Ljava/lang/String;)V
    .registers 5
    invoke-static {p0}, LIdric/Generated;->search_request_from_intent(Landroid/content/Intent;)Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :passed
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    const-string v2, "FAIL actual IB Intent query export"
    invoke-virtual {v1, v2}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
  :passed
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 4
    new-instance v0, Landroid/content/Intent;
    invoke-direct {v0}, Landroid/content/Intent;-><init>()V
    const-string v1, ""
    invoke-static {v0, v1}, Lacceptance/SearchExportObserver;->expect(Landroid/content/Intent;Ljava/lang/String;)V
    const-string v1, "query"
    const-string v2, "Björk & C# chords"
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v2, "https://google.com/search?q=Bj%C3%B6rk+%26+C%23+chords"
    invoke-static {v0, v2}, Lacceptance/SearchExportObserver;->expect(Landroid/content/Intent;Ljava/lang/String;)V
    const-string v2, "bad\nquery"
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v2, ""
    invoke-static {v0, v2}, Lacceptance/SearchExportObserver;->expect(Landroid/content/Intent;Ljava/lang/String;)V
    const-string v2, "  a + b  "
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v2, "https://google.com/search?q=a+%2B+b"
    invoke-static {v0, v2}, Lacceptance/SearchExportObserver;->expect(Landroid/content/Intent;Ljava/lang/String;)V
    const-string v2, "  𝄞+λ  "
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v2, "https://google.com/search?q=%F0%9D%84%9E%2B%CE%BB"
    invoke-static {v0, v2}, Lacceptance/SearchExportObserver;->expect(Landroid/content/Intent;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS unchanged IB search export on ART"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
.end method
