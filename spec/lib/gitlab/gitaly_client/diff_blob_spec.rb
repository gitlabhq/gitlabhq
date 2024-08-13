# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::DiffBlob, feature_category: :gitaly do
  let(:diff_blob_fields) do
    {
      left_blob_id: '357406f3075a57708d0163752905cc1576fceacc',
      right_blob_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
      patch: 'a' * 100,
      status: :STATUS_END_OF_PATCH,
      binary: false,
      over_patch_bytes_limit: false
    }
  end

  subject(:diff_blob) { described_class.new(diff_blob_fields) }

  it { is_expected.to respond_to(:left_blob_id) }
  it { is_expected.to respond_to(:right_blob_id) }
  it { is_expected.to respond_to(:patch) }
  it { is_expected.to respond_to(:status) }
  it { is_expected.to respond_to(:binary) }
  it { is_expected.to respond_to(:over_patch_bytes_limit) }
end
