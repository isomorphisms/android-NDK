.class public final LCapturedRunnableRunner;
.super Ljava/lang/Object;

.method private static requireText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .registers 5
    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ok
    new-instance v0, Ljava/lang/AssertionError;
    invoke-direct {v0, p2}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v0
  :ok
    return-void
.end method

.method private static requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    .registers 4
    invoke-static {p0}, LIdric/Generated;->read_captured_sink(Ljava/lang/StringBuilder;)Ljava/lang/String;
    move-result-object v0
    invoke-static {v0, p1, p2}, LCapturedRunnableRunner;->requireText(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

# Returning only Thread removes the source factory's caller-local Runnable.
# Thread retains the callback until later platform dispatch.
.method private static retainedThread(Ljava/lang/StringBuilder;)Ljava/lang/Thread;
    .registers 4
    const-string v0, "retained"
    const/4 v1, 0x0
    invoke-static {p0, v0, v1}, LIdric/Generated;->make_captured_runnable(Ljava/lang/StringBuilder;Ljava/lang/String;Z)Ljava/lang/Runnable;
    move-result-object v0
    new-instance v1, Ljava/lang/Thread;
    invoke-direct {v1, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;)V
    return-object v1
.end method

.method private static pressure()V
    .registers 5
    new-instance v0, Ljava/util/ArrayList;
    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V
    const/4 v1, 0x0
    const/16 v2, 0x40
    const v3, 0x10000
  :allocate
    new-array v4, v3, [B
    invoke-virtual {v0, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    add-int/lit8 v1, v1, 0x1
    if-lt v1, v2, :allocate
    invoke-static {}, Ljava/lang/System;->gc()V
    invoke-virtual {v0}, Ljava/util/ArrayList;->clear()V
    invoke-static {}, Ljava/lang/System;->gc()V
    return-void
.end method

.method public static main([Ljava/lang/String;)V
    .registers 3
  :observation_start
    invoke-static {}, LCapturedRunnableRunner;->observe()V
  :observation_end
    .catch Ljava/lang/AssertionError; {:observation_start .. :observation_end} :assertion_failed
    .catch Ljava/lang/Throwable; {:observation_start .. :observation_end} :unexpected_throwable
    return-void
  :assertion_failed
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const/16 v0, 93
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
  :unexpected_throwable
    move-exception v0
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, v1}, Ljava/lang/Throwable;->printStackTrace(Ljava/io/PrintStream;)V
    const/16 v0, 94
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

.method private static observe()V
    .registers 14
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    const-string v3, "α"
    const/4 v4, 0x0
    invoke-static {v0, v3, v4}, LIdric/Generated;->make_captured_runnable(Ljava/lang/StringBuilder;Ljava/lang/String;Z)Ljava/lang/Runnable;
    move-result-object v5
    const-string v3, "β"
    const/4 v4, 0x1
    invoke-static {v1, v3, v4}, LIdric/Generated;->make_captured_runnable(Ljava/lang/StringBuilder;Ljava/lang/String;Z)Ljava/lang/Runnable;
    move-result-object v6
    invoke-static {v2}, LCapturedRunnableRunner;->retainedThread(Ljava/lang/StringBuilder;)Ljava/lang/Thread;
    move-result-object v7
    if-ne v5, v6, :distinct
    new-instance v3, Ljava/lang/AssertionError;
    const-string v4, "factories returned one shared Runnable"
    invoke-direct {v3, v4}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v3
  :distinct
    const-string v3, ""
    const-string v4, "creation ran source action eagerly"
    invoke-static {v0, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v1, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v2, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, LCapturedRunnableRunner;->pressure()V
    invoke-interface {v6}, Ljava/lang/Runnable;->run()V
    invoke-interface {v5}, Ljava/lang/Runnable;->run()V
    invoke-interface {v5}, Ljava/lang/Runnable;->run()V
    const-string v3, "α:α|λ🙂|tailα:α|λ🙂|tail"
    const-string v4, "repeated action mutated or lost its captured closure"
    invoke-static {v0, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    const-string v3, "β:tail|λ🙂|β"
    const-string v4, "ADT branch/list order or per-instance capture differed"
    invoke-static {v1, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-virtual {v7}, Ljava/lang/Thread;->start()V
    const-wide/16 v8, 0x1388
    invoke-virtual {v7, v8, v9}, Ljava/lang/Thread;->join(J)V
    invoke-virtual {v7}, Ljava/lang/Thread;->isAlive()Z
    move-result v3
    if-eqz v3, :joined
    new-instance v3, Ljava/lang/AssertionError;
    const-string v4, "retained Thread action did not finish"
    invoke-direct {v3, v4}, Ljava/lang/AssertionError;-><init>(Ljava/lang/Object;)V
    throw v3
  :joined
    const-string v3, "retained:retained|λ🙂|tail"
    const-string v4, "Thread lost captured source state after factory return/GC pressure"
    invoke-static {v2, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {}, Ljava/util/concurrent/Executors;->newSingleThreadExecutor()Ljava/util/concurrent/ExecutorService;
    move-result-object v10
  :executor_start
    invoke-interface {v10, v5}, Ljava/util/concurrent/ExecutorService;->submit(Ljava/lang/Runnable;)Ljava/util/concurrent/Future;
    move-result-object v11
    const-wide/16 v8, 0x5
    sget-object v12, Ljava/util/concurrent/TimeUnit;->SECONDS:Ljava/util/concurrent/TimeUnit;
    invoke-interface {v11, v8, v9, v12}, Ljava/util/concurrent/Future;->get(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;
  :executor_end
    .catchall {:executor_start .. :executor_end} :executor_failed
    invoke-interface {v10}, Ljava/util/concurrent/ExecutorService;->shutdown()V
    const-string v3, "α:α|λ🙂|tailα:α|λ🙂|tailα:α|λ🙂|tail"
    const-string v4, "Executor dispatch did not reuse the checked action"
    invoke-static {v0, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    invoke-static {v6}, LIdric/Generated;->dispatch_captured_runnable(Ljava/lang/Runnable;)V
    const-string v3, "β:tail|λ🙂|ββ:tail|λ🙂|β"
    const-string v4, "source interface dispatch changed capture semantics"
    invoke-static {v1, v3, v4}, LCapturedRunnableRunner;->requireSink(Ljava/lang/StringBuilder;Ljava/lang/String;Ljava/lang/String;)V
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS checked captured Runnable: isolated ADT/Text/list, deferred/repeated run, retained Thread, Executor"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
  :executor_failed
    move-exception v11
    invoke-interface {v10}, Ljava/util/concurrent/ExecutorService;->shutdownNow()Ljava/util/List;
    throw v11
.end method
