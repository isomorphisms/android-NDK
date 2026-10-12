.class public final LIdric/ParcelEffectsRunner;
.super Ljava/lang/Object;

# External ART oracle for QuickSettingsSourceEffects.idric. Run with its
# candidate DEX separately: both candidate fixtures use LIdric/Generated;.
# All writes and reads under test must execute in that candidate. Runner-side
# Parcel calls supply input and independently inspect the resulting state.

.method public static main([Ljava/lang/String;)V
    .registers 4

    invoke-static {}, Landroid/os/Parcel;->obtain()Landroid/os/Parcel;
    move-result-object v0
    const/16 v1, 0x5b
    invoke-virtual {v0, v1}, Landroid/os/Parcel;->writeInt(I)V
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/os/Parcel;->setDataPosition(I)V

    # Both primitive and IO-wrapped reads must observe the real value 91.
    invoke-static {v0}, LIdric/Generated;->primitive_read(Landroid/os/Parcel;)I
    move-result v1
    const/16 v2, 0x5b
    if-ne v1, v2, :fail_primitive
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/os/Parcel;->setDataPosition(I)V
    invoke-static {v0}, LIdric/Generated;->wrapped_read(Landroid/os/Parcel;)I
    move-result v1
    const/16 v2, 0x5b
    if-ne v1, v2, :fail_wrapped

    # Replace the input with 31337 through the candidate's ordered
    # writeInt(value), setDataPosition(0), readInt sequence.
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/os/Parcel;->setDataPosition(I)V
    const/16 v1, 0x7a69
    invoke-static {v0, v1}, LIdric/Generated;->write_then_read(Landroid/os/Parcel;I)I
    move-result v1
    const/16 v2, 0x7a69
    if-ne v1, v2, :fail_sequence_result

    # Reading one Int32 leaves position 4. Check this before the oracle seeks.
    invoke-virtual {v0}, Landroid/os/Parcel;->dataPosition()I
    move-result v1
    const/4 v2, 0x4
    if-ne v1, v2, :fail_sequence_position
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/os/Parcel;->setDataPosition(I)V
    invoke-virtual {v0}, Landroid/os/Parcel;->readInt()I
    move-result v1
    const/16 v2, 0x7a69
    if-ne v1, v2, :fail_sequence_store

    # Complete the void and returned-object lifecycle paths. Do not access a
    # recycled Parcel to manufacture an unsupported observation of its state.
    invoke-static {v0}, LIdric/Generated;->wrapped_recycle(Landroid/os/Parcel;)V
    invoke-static {}, LIdric/Generated;->obtain_then_recycle()V

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "quick-settings source effects PASS"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

  :fail_primitive
    const/16 v3, 0x51
    goto :fail_exit
  :fail_wrapped
    const/16 v3, 0x52
    goto :fail_exit
  :fail_sequence_result
    const/16 v3, 0x53
    goto :fail_exit
  :fail_sequence_position
    const/16 v3, 0x54
    goto :fail_exit
  :fail_sequence_store
    const/16 v3, 0x55
  :fail_exit
    # Distinct nonzero exits 81-85 locate the failed observable contract.
    invoke-static {v3}, Ljava/lang/System;->exit(I)V
    return-void
.end method
