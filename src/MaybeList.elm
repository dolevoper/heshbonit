module MaybeList exposing (..)


fromListMaybe : List (Maybe a) -> Maybe (List a)
fromListMaybe =
    List.foldr (\a b -> Maybe.andThen (\c -> Maybe.map ((::) c) b) a) (Just [])
