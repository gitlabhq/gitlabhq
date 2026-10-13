# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Encryption::DbKeyBaseLockboxKeys, feature_category: :system_access do
  include DbKeyBaseHelpers

  let(:test_class) do
    Class.new do
      include Gitlab::Encryption::DbKeyBaseLockboxKeys

      public :db_key_base_lockbox_key, :db_key_base_lockbox_previous_versions
    end
  end

  let(:keys) { test_class.new }
  let(:context) { 'some-context' }

  def derived(secret)
    OpenSSL::HMAC.digest('SHA256', secret, context)
  end

  context 'with a single key' do
    it 'derives the key from the current key' do
      expect(keys.db_key_base_lockbox_key(context)).to eq(derived(Settings.db_key_base_keys.last))
    end

    it 'has no previous versions' do
      expect(keys.db_key_base_lockbox_previous_versions(context)).to be_empty
    end
  end

  context 'with several keys' do
    before do
      stub_db_key_base_keys('oldest', 'old', 'current')
    end

    it 'derives the key from the current key' do
      expect(keys.db_key_base_lockbox_key(context)).to eq(derived('current'))
    end

    it 'lists the older keys, newest first' do
      expect(keys.db_key_base_lockbox_previous_versions(context))
        .to eq([{ key: derived('old') }, { key: derived('oldest') }])
    end
  end

  it 'skips older keys identical to the current key' do
    stub_db_key_base_keys('current', 'old', 'current')

    expect(keys.db_key_base_lockbox_previous_versions(context)).to eq([{ key: derived('old') }])
  end
end
