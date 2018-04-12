
fun put [fields] [uniques] (injs : $(map sql_injectable fields)) (fl : folder fields)
    (tab : sql_table fields uniques) (fs : $fields) =
    dml (insert tab (@Top.map2 [sql_injectable] [fn s => s] [sql_exp [] [] []]
                     (fn [t] => @sql_inject)
                     fl injs fs))
