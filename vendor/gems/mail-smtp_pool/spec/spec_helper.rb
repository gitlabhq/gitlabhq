# frozen_string_literal: true

require 'mail/smtp_pool'

# Original mockup from ActionMailer
# Based on https://github.com/mikel/mail/blob/22a7afc23f253319965bf9228a0a430eec94e06d/spec/spec_helper.rb#L74-L138
class MockSMTP
  def self.deliveries
    @@deliveries
  end

  def self.security
    @@security
  end

  def initialize
    @@deliveries = []
    @@security = nil
    @started = false
  end

  def sendmail(mail, from, to)
    @@deliveries << [mail, from, to]
    'OK'
  end

  def rset
    Net::SMTP::Response.parse('250 OK')
  end

  def start(*args)
    @started = true

    if block_given?
      result = yield(self)
      @started = false

      return result
    else
      return self
    end
  end

  def started?
    @started
  end

  def finish
    @started = false
    return true
  end

  def self.clear_deliveries
    @@deliveries = []
  end

  def self.clear_security
    @@security = nil
  end

  def enable_tls(context)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@security && @@security != :enable_tls
    @@security = :enable_tls
    context
  end

  def enable_starttls(context = nil)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@security == :enable_tls
    @@security = :enable_starttls
    context
  end

  def enable_starttls_auto(context)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@security == :enable_tls
    @@security = :enable_starttls_auto
    context
  end
end

class Net::SMTP
  def self.new(*args)
    MockSMTP.new
  end
end
