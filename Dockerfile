# Let it be the latest one
ARG PERL=latest
ARG APP=v1.0

FROM perl:${PERL}

LABEL id="perl_${PERL}-dancer2-book_catalogue-${APP}"
LABEL version="${APP}"
LABEL maintainer="Vasyl Kupchenko basilwashere[at]gmail.com"

ADD . /opt/MyApp
WORKDIR /opt/MyApp

#RUN perl -E "$|++; say foreach('Fast debug info:', $^X, $^V, scalar qx[which perl], scalar qx[/usr/bin/perl -v], scalar qx[ls -ahl]); exit 1"

# In case if there is a year 2021 and the issue with multiple Perls is still not resolved
RUN perl -E "$^V gt v5.23 or exit 1" \
    && perl -E "exit 0 if (qx[which perl] ne q[/usr/bin/perl])" \
    || perl -pi -E 'BEGIN{ chomp($r = qx[which perl]) } s:/usr/bin/perl:$r:g' $( find ./ -name *.psgi -o -name *.t -o -name *.pl )

RUN cpanm App::cpm --notest \
    && cpm install --global --show-build-log-on-failure Dancer2 Dancer2::Plugin::DBIC Dancer2::Template::Xslate Date::Manip Text::CSV \
    && chmod a+x *.pl

RUN perl app.pl recreate && perl app.pl load

EXPOSE 8080

ENTRYPOINT ['perl', 'app.pl']
