.class public Lacceptance/ArgumentIndexObserver;
.super Ljava/lang/Object;

# Only the candidate owns argument storage/access. This oracle independently
# requires exceptions for negative, absent and overflowing source indices.
.method public static main([Ljava/lang/String;)V
    .registers 8
    invoke-static {p0}, LIdric/Generated;->main([Ljava/lang/String;)V

  :negative_start
    const-wide/16 v2, -0x1
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :negative_end
    goto :bad
  :negative_caught
    move-exception v0

  :absent_start
    const-wide/16 v2, 0x1
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :absent_end
    goto :bad
  :absent_caught
    move-exception v0

  :overflow_start
    const-wide v2, 0x80000000L
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :overflow_end
    goto :bad
  :overflow_caught
    move-exception v0

  :underflow_start
    const-wide v2, -0x8000000000000000L
    invoke-static {v2, v3}, LIdric/Generated;->__idricArg(J)Ljava/lang/String;
  :underflow_end
    goto :bad
  :underflow_caught
    move-exception v0
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked argument index refusals"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

  :bad
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
    .catch Ljava/lang/IndexOutOfBoundsException; {:negative_start .. :negative_end} :negative_caught
    .catch Ljava/lang/IndexOutOfBoundsException; {:absent_start .. :absent_end} :absent_caught
    .catch Ljava/lang/ArithmeticException; {:overflow_start .. :overflow_end} :overflow_caught
    .catch Ljava/lang/ArithmeticException; {:underflow_start .. :underflow_end} :underflow_caught
.end method
