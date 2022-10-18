module Session exposing (Session)

import AccountData exposing (AccountData)
import Browser.Navigation exposing (Key)
import Invoices exposing (Invoices)
import User exposing (User)


type alias Session =
    { navKey : Key
    , uid : String
    , accountData : Maybe AccountData
    , invoices : Maybe Invoices
    , user : Maybe User
    }
