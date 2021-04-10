# Mail::SMTPPool

This gem is an extension to `Mail` that allows delivery of emails using an SMTP connection pool

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mail-smtp_pool'
```

And then execute:

```shell
bundle
```

Or install it yourself as:

```shell
gem install mail-smtp_pool
```

## Usage with ActionMailer

```ruby
# config/environments/development.rb

Rails.application.configure do
  ...

  ActionMailer::Base.add_delivery_method :smtp_pool, Mail::SMTPPool

  config.action_mailer.perform_deliveries = true
  config.action_mailer.smtp_pool_settings = {
    pool: Mail::SMTPPool.create_pool(
      pool_size:            5,
      pool_timeout:         5,
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'example.com',
      user_name:            '<username>',
      password:             '<password>',
      authentication:       'plain',
      enable_starttls_auto: true
    )
  }
end
```

Configuration options:

* `pool_size` - The maximum number of SMTP connections in the pool. Connections are created lazily as needed.
* `pool_timeout` - The number of seconds to wait for a connection in the pool to be available. A `Timeout::Error` exception is raised when this is exceeded.

This also accepts all options supported by `Mail::SMTP`. See https://www.rubydoc.info/gems/mail/2.6.1/Mail/SMTP for more information.
