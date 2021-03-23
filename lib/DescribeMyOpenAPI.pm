# Generate OpenAPI 3.0.0 specification from routes
# I found something similar only for the Dancer1
package DescribeMyOpenAPI v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings; no warnings 'experimental';
    use utf8;

    use Encode 'encode_utf8';
    use JSON::MaybeXS;
    use YAML 'Dump';

    my $collection = {};
    my $openAPI = {
        openapi => '3.0.0',
        info => {
            version => main->VERSION // v0.0.0,
        },
        paths => {},
    };
    my $openAPI_json = '{}';
    my $openAPI_yaml = '---';

    sub import ($self, $source = undef) {
        return 1 unless (defined $source);
        my ($module, $path) = (caller(0))[0,1];
        $collection->{"$source"} = {
            object => $source,
            module => $module,
            path => $path,
            processed => 0,
            version => $module->VERSION,
        };
    }

    sub Show ($type = 'json') {
        foreach my $app (values %$collection) {
            goto &Generate unless ($app->{processed});
        }
        Return($type);
    }

    sub Generate ($type = 'json') {
        foreach my $app (values %$collection) {
            my ($appname, $content_type, $environment) = $app->{object}->config->@{'appname', 'content_type', 'environment'};
            $openAPI->{info}->{title}       //= $appname;
            $openAPI->{info}->{description} //= "$appname (on $environment). Aggregated from: ";
            $openAPI->{info}->{description} .= $app->{module} . ' ';

            while (my ($http_method, $routes_collection) = each $app->{object}->routes->%*) {
                next unless (scalar @$routes_collection);

                foreach my $route (@$routes_collection) {
                    my $has_params = scalar $route->{_params}->@*;
                    my $rel_path = $route->{spec_route};
                    my $prefix = $route->{prefix};

                    # TODO: better prefix detection
                    my $full_path = ($prefix // '') . $rel_path;
                    if ($has_params) {
                        # Translate "/book/:id" into "/book{id}"
                        $full_path =~ s/:(?<parameter> [[:word:]-]+ )/\{$+{parameter}\}/gx;
                    }

                    # Optional character at the end -> remove it. It's 2021 and OpenAPI still does not support optional parts
                    $full_path =~ s/.\?\Z//;

                    $openAPI->{paths}->{$full_path}->{$http_method}->{responses}->{'200'}->{description} = 'OK';
                    #$openAPI->{paths}->{$full_path}->{$http_method}->{responses}->{'200'}->{content}->{$content_type}->{description} = 'OK';
                }
            }
        }
        chop $openAPI->{info}->{description};

        $openAPI_json = encode_utf8(encode_json($openAPI));
        $openAPI_yaml = encode_utf8(Dump($openAPI));

        foreach my $id (keys %$collection) {
            $collection->{$id}->{processed} = 1;
        }

        Return($type);
    }

    sub Return($type) {
        given ($type) {
            when ('json') { $openAPI_json }
            when ('yaml') { $openAPI_yaml }
            default { warn "Unknown type [$type] requested!"}
        }
    }

    1;
}
