# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GitalyClient::Diff do
  let(:diff_fields) do
    {
      to_path: ".gitmodules",
      from_path: ".gitmodules",
      old_mode: 0100644,
      new_mode: 0100644,
      from_id: '357406f3075a57708d0163752905cc1576fceacc',
      to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
      patch: 'a' * 100,
      collapsed: false,
      too_large: false
    }
  end

  subject { described_class.new(diff_fields) }

  it { is_expected.to respond_to(:from_path) }
  it { is_expected.to respond_to(:to_path) }
  it { is_expected.to respond_to(:old_mode) }
  it { is_expected.to respond_to(:new_mode) }
  it { is_expected.to respond_to(:from_id) }
  it { is_expected.to respond_to(:to_id) }
  it { is_expected.to respond_to(:patch) }
  it { is_expected.to respond_to(:collapsed) }
  it { is_expected.to respond_to(:too_large) }

  describe '#==' do
    it { expect(subject).to eq(described_class.new(diff_fields)) }
    it { expect(subject).not_to eq(described_class.new(diff_fields.merge(patch: 'a'))) }
  end
end
