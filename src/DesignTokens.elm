module DesignTokens exposing (elevation)

import Css exposing (property)


elevation : { low : Css.Style, medium : Css.Style, high : Css.Style }
elevation =
    { low = property "box-shadow" "0.2px 0.3px 0.4px hsl(0deg 0% 63% / 0.34), 0.3px 0.4px 0.6px -1.2px hsl(0deg 0% 63% / 0.34), 0.7px 1px 1.4px -2.5px hsl(0deg 0% 63% / 0.34);"
    , medium = property "box-shadow" "0.2px 0.3px 0.4px hsl(0deg 0% 63% / 0.36), 0.6px 0.8px 1.1px -0.8px hsl(0deg 0% 63% / 0.36), 1.5px 2.1px 2.9px -1.7px hsl(0deg 0% 63% / 0.36), 3.6px 5px 6.9px -2.5px hsl(0deg 0% 63% / 0.36);"
    , high = property "box-shadow" "0.2px 0.3px 0.4px hsl(0deg 0% 63% / 0.38), 1.2px 1.7px 2.3px -0.4px hsl(0deg 0% 63% / 0.38), 2.4px 3.3px 4.6px -0.8px hsl(0deg 0% 63% / 0.38), 4.1px 5.7px 7.9px -1.2px hsl(0deg 0% 63% / 0.38), 7px 9.7px 13.5px -1.7px hsl(0deg 0% 63% / 0.38), 11.6px 16px 22.2px -2.1px hsl(0deg 0% 63% / 0.38), 18.2px 25.2px 35px -2.5px hsl(0deg 0% 63% / 0.38);"
    }
