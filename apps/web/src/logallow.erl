-module(logallow).
-compile(export_all).

log_modules() -> [
    wf_core,
%    n2o_bullet,
    game_session,
    n2o_secret,
    js_session,
    okey
].