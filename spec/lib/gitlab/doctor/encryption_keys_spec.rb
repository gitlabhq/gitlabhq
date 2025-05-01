# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Doctor::EncryptionKeys, feature_category: :shared do
  let(:logger) { instance_double(Logger).as_null_object }

  subject(:doctor_encryption_secrets) { described_class.new(logger).run! }

  it 'outputs current encryption secrets IDs, and truncated actual secrets' do
    expect(logger).to receive(:info)
      .with(/- active_record_encryption_primary_key: ID => `\w{4}`; truncated secret => `\w{3}...\w{3}`/)
    expect(logger).to receive(:info)
      .with(/- active_record_encryption_deterministic_key: ID => `\w{4}`; truncated secret => `\w{3}...\w{3}`/)

    doctor_encryption_secrets
  end
end
