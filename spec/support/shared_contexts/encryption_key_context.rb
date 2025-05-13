# frozen_string_literal: true

RSpec.shared_context 'with encryption key' do |key_type, secret|
  before do
    key = instance_double(ActiveRecord::Encryption::Key, secret: secret)
    key_provider = instance_double(Gitlab::Encryption::KeyProviderWrapper, encryption_key: key)
    allow(Gitlab::Encryption::KeyProvider).to receive(:[]).with(key_type).and_return(key_provider)
  end
end
