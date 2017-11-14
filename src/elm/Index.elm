module Index exposing (decoder)

import Json.Decode as JD exposing (Decoder)
import Types exposing (..)


decoder : Decoder Index
decoder =
    JD.list package


package : Decoder Package
package =
    JD.map5 Package
        (JD.field "author" JD.string)
        (JD.field "name" JD.string)
        (JD.field "version" JD.string)
        (JD.field "isUserPackage" JD.bool)
        (JD.field "modules" (JD.list module_))


module_ : Decoder Module
module_ =
    JD.map2 Module
        (JD.field "name" JD.string)
        (JD.field "definitions" (JD.list JD.string))
