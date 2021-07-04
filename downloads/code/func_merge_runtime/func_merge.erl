-module(func_merge).

-compile([{parse_transform, func_merge_runtime}]).

-load_all(func_a).
-load_all(func_b).

-load_func({func_a, [a/0, b/0]}).

-compile(export_all).

a(1) -> func_merge_a1;
a(2) -> func_merge_a2;
a(_) -> func_merge_a3.

a(_, _) -> [].

a() -> func_merge_a.
