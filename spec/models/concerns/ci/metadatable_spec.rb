# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Metadatable, feature_category: :continuous_integration do
  describe '#timeout_value' do
    using RSpec::Parameterized::TableSyntax

    let(:ci_processable) { build(:ci_processable, metadata: ci_build_metadata) }
    let(:ci_build_metadata) { build(:ci_build_metadata, timeout: metadata_timeout) }

    subject(:timeout_value) { ci_processable.timeout_value }

    before do
      allow(ci_processable).to receive_messages(timeout: build_timeout)
    end

    where(:build_timeout, :metadata_timeout, :expected_timeout) do
      nil | nil | nil
      nil | 100 | 100
      200 | nil | 200
      200 | 100 | 200
    end

    with_them do
      it { is_expected.to eq(expected_timeout) }
    end
  end
end
