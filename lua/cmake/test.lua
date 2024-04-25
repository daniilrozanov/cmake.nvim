local lyaml = require("cmake.lyaml")
lyaml.dump({ { foo = "bar" } })
--> ---
--> foo: bar
--> ...

lyaml.dump({ "one", "two" })
--> --- one
--> ...
--> --- two
--> ...
