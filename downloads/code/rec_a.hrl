-record(name, {
    first = "",
    last = ""
}).

-record(person, {
    id = 0
    ,name = #name{first="aaa", last="bbb"}
    ,names = [#name{first="abc"}, #name{last="def"}]
    ,sex = 0
}).
