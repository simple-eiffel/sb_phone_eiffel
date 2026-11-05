@echo off
REM Builds sqlite3_fts4.obj here from the library's sqlite3.c, with the flags of eifphone.toml, so
REM that the PC targets read app.db as the phone does. Run from any prompt; nothing else is written.
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
cd /d "%~dp0"
cl /nologo /c /MT /O2 /W0 /DSQLITE_THREADSAFE=1 /DSQLITE_ENABLE_FTS3 /DSQLITE_ENABLE_FTS4 /DSQLITE_ENABLE_FTS5 /DSQLITE_ENABLE_JSON1 /DSQLITE_ENABLE_RTREE /DSQLITE_ENABLE_GEOPOLY /DSQLITE_ENABLE_MATH_FUNCTIONS /DSQLITE_OMIT_LOAD_EXTENSION /DSQLITE_ENABLE_COLUMN_METADATA /DSQLITE_TEMP_STORE=3 /Fosqlite3_fts4.obj D:\prod\eiffel_sqlite_2025\Clib\sqlite3.c
