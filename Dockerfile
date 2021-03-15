# Let it be the latest one
ARG PERL=latest

FROM perl:${PERL}
# Duplicate is necessary since the first ARG is outside of the build scope
ARG PERL=latest
ARG APP=v1.0
ARG APP_DIR=/opt/MyApp

LABEL id="perl_${PERL}-dancer2-book_catalogue-${APP}"
LABEL version="$APP"
LABEL maintainer='Vasyl Kupchenko basilwashere[at]gmail.com'

ADD . $APP_DIR
WORKDIR $APP_DIR
ENV PATH "$PATH:${APP_DIR}"

#RUN perl -E "$|++; say foreach('Fast debug info:', $^X, $^V, scalar qx[which perl], scalar qx[/usr/bin/perl -v], scalar qx[ls -ahl]); exit 1"

# In case if there is a year 2021 and the issue with multiple Perls is still not resolved
RUN ( perl -E "exit 1 if (qx[which perl] ne q[/usr/bin/perl])" \
    || perl -pi -E 'BEGIN{ chomp($a = qx[which perl]) } s:/usr/bin/perl:$a:g' $( find ./ -name '*.psgi' -o -name '*.t' -o -name '*.pl' ) ) \
    && perl -E "$^V gt v5.23 or exit 1" \
# Unbelievable! Issue with line endings does not want to stay in the previous millennium and is back!
    && perl -pi -E 's:[\012\015]{1,2}:$/:gn' $( find ./ -name '*.psgi' -o -name '*.t' -o -name '*.pl' ) \
    && cpanm App::cpm --notest \
    && cpm install --global --show-build-log-on-failure Dancer2 Dancer2::Plugin::DBIC Dancer2::Template::Xslate Date::Manip Text::CSV Gazelle B::Lint \
    && chmod a+x *.pl \
    && perl app.pl recreate --yes load

EXPOSE 8080

ENTRYPOINT ["app.pl"]
