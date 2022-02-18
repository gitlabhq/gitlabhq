# frozen_string_literal: true

require 'ostruct'

# Helper methods for controller specs in the Import namespace
#
# Must be included manually.
module ImportSpecHelper
  # Stub `controller` to return a null object double with the provided messages
  # when `client` is called
  #
  # Examples:
  #
  #   stub_client(foo: %w(foo))
  #
  #   controller.client.foo         # => ["foo"]
  #   controller.client.bar.baz.foo # => ["foo"]
  #
  # Returns the client double
  def stub_client(messages = {})
    client = double('client', messages).as_null_object
    allow(controller).to receive(:client).and_return(client)

    client
  end

  def stub_omniauth_provider(name)
    provider = ActiveSupport::InheritableOptions.new(
      name: name,
      app_id: 'asd123',
      app_secret: 'asd123'
    )
    stub_omniauth_setting(providers: [provider])
  end
end
