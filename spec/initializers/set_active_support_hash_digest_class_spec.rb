# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'setting ActiveSupport::Digest.hash_digest_class' do
  it 'sets overrides config.active_support.hash_digest_class' do
    expect(ActiveSupport::Digest.hash_digest_class).to eq(Gitlab::HashDigest::Facade)
  end
end
