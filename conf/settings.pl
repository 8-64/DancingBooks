sub DEV () { 1 }              # Am I developing?
package Settings;
sub E ()         { 'deployment' }   # Environment
sub port ()      { 8080 }           # Port for the web
sub server ()    { 'Thrall' }      # Server to use
sub workers ()   { 10 }             # N of workers, where applicable
sub key_file ()  { 'crt/localhost.key' }
sub cert_file () { 'crt/localhost.cert' }
sub use_ssl ()   { 0 }
sub host ()      { 'localhost' }

1;
