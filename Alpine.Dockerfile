# Let it be the latest one
ARG TYPE=latest

FROM alpine:${TYPE}
# Duplicate is necessary since the first ARG is outside of the build scope
ARG TYPE=latest
ARG APP=v1.0
ARG APP_DIR=/opt/MyApp

LABEL id="alpine(${TYPE})-perl(${TYPE})-dancer2-book_catalogue(${APP})"
LABEL version="$APP"
LABEL maintainer='Vasyl Kupchenko basilwashere[at]gmail.com'

ADD . $APP_DIR
WORKDIR $APP_DIR
ENV PATH "$PATH:${APP_DIR}"

# Surprisingly easy to configure and use in comparison with the "official" Perl docker image distribution. WHY?
RUN apk add perl perl-dev perl-utils perl-app-cpanminus perl-libwww \
    && apk add curl make bash \
    && apk add gcc libc-dev \
    && cpanm App::cpm --notest \
    && cpm install --global --show-build-log-on-failure Dancer2 Dancer2::Plugin::DBIC Dancer2::Template::Xslate Date::Manip Text::CSV Gazelle B::Lint \
    && chmod a+x *.pl \
    # But the issue with line endings is ever-present :)
    && perl -pi -E 's:[\012\015]{1,2}:$/:gn' $( find ./ -name '*.psgi' -o -name '*.t' -o -name '*.pl' ) \
    && perl app.pl recreate --yes load

EXPOSE 8080

ENTRYPOINT ["app.pl"]
