@for %%f in (*.c) do grep -i+ -n+ %1 %%f
@for %%f in (*.c68) do grep -i+ -n+ %1 %%f
@for %%f in (*.s) do grep -i+ -n+ %1 %%f
@for %%f in (*.asm) do grep -i+ -n+ %1 %%f
@for %%f in (*.inc) do grep -i+ -n+ %1 %%f
@for %%f in (*.equ) do grep -i+ -n+ %1 %%f
@for %%f in (*.h) do grep -i+ -n+ %1 %%f
