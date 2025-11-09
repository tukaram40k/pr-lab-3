FROM ruby:3.2-alpine

RUN apk add --no-cache \
    build-base \
    && mkdir -p /app

WORKDIR /app
COPY Gemfile* ./

RUN bundle install

COPY . .

RUN mkdir -p logs

EXPOSE 4567
ENV RACK_ENV=production

CMD ["bundler", "exec", "ruby", "main.rb"]