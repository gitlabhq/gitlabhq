# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JWTToken do
  it_behaves_like 'a gitlab jwt token'

  describe '.decode with several db_key_base keys' do
    include DbKeyBaseHelpers

    let(:new_key) { SecureRandom.hex(64) }

    it 'decodes a token signed with the previous key' do
      token = described_class.new.tap { |jwt| jwt['data'] = 'value' }
      stub_db_key_base_keys(Settings.db_key_base_keys.last, new_key)

      expect(described_class.decode(token.encoded)['data']).to eq('value')
    end

    it 'rejects a token signed with a key that is no longer configured' do
      token = described_class.new.tap { |jwt| jwt['data'] = 'value' }
      stub_db_key_base_keys(new_key)

      expect(described_class.decode(token.encoded)).to be_nil
    end

    it 'signs new tokens with the current key' do
      stub_db_key_base_keys(Settings.db_key_base_keys.last, new_key)
      token = described_class.new.tap { |jwt| jwt['data'] = 'value' }
      stub_db_key_base_keys(new_key)

      expect(described_class.decode(token.encoded)['data']).to eq('value')
    end
  end
end
