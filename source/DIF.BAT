@echo off
xdir %1 /L
xdir m:\transfer\nrush\updates\%1 /L
pause
diff %1 m:\transfer\nrush\updates\%1 | more
