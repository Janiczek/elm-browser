module FilterConfig exposing (..)

import Types exposing (..)


empty : FilterConfig
empty =
    { packages =
        { user = False
        , directDeps = False
        , depsOfDeps = False
        }
    , modules =
        { exposed = False
        , effect = False
        , port_ = False
        }
    , definitions =
        { exposed = False
        }
    }
