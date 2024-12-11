-module(cache).
-export([create/1, insert/3, insert/4, lookup/2, delete_obsolete/1]).


create(TableName) ->
    ets:new(TableName, [named_table, public, set]),
    ok.

 
insert(TableName, Key, Value) ->
    Timestamp = infinity,
    ets:insert(TableName, {Key, Value, Timestamp}),
    ok.

insert(TableName, Key, Value, TTL) when is_integer(TTL), TTL > 0 ->
    {_, CurrentTime} = calendar:local_time(),
    Expiration = CurrentTime + TTL,
    ets:insert(TableName, {Key, Value, Expiration}),
    ok.

lookup(TableName, Key) ->
    case ets:lookup(TableName, Key) of
        [] -> undefined;
        [{_, Value, infinity}] -> Value;
        [{_, Value, Expiration}] ->
            {_, CurrentTime} = calendar:local_time(),
            if
                Expiration > CurrentTime -> Value;
                true -> undefined
            end
    end.

delete_obsolete(TableName) ->
    {_, CurrentTime} = calendar:local_time(),
    ObsoleteKeys = [Key || {Key, _, Expiration} <- ets:tab2list(TableName), Expiration =/= infinity, Expiration =< CurrentTime],
    lists:foreach(fun(Key) -> ets:delete(TableName, Key) end, ObsoleteKeys),
    ok.
