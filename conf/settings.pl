sub DEV ()               { 1 }              # Am I developing?
sub Settings::E ()       { 'deployment' }   # Environment
sub Settings::PORT ()    { 8080 }           # Port for the web
sub Settings::Server ()  { 'Gazelle' }      # Server to use
sub Settings::Workers () { 10 }             # N of workers, where applicable

1;
