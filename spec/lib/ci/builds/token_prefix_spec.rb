# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Builds::TokenPrefix, feature_category: :continuous_integration do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:job, freeze: false) { build_stubbed(:ci_build, partition_id: 201) }

  let(:encoded_partition_id) { 201.to_s(16) }

  describe '.encode' do
    subject(:encode) { described_class.encode(job) }

    it { is_expected.to match(/^#{Ci::Build::TOKEN_PREFIX}#{encoded_partition_id}_$/o) }
  end

  describe '.decode_partition' do
    subject(:decode_partition) { described_class.decode_partition(token) }

    context 'with valid token' do
      let(:token) { job.ensure_token }

      it { is_expected.to eq(201) }
    end

    context 'with invalid tokens' do
      let(:token) { 'somestring' }

      it { is_expected.to be_nil }
    end

    context 'with invalid tokens containing underscores' do
      let(:token) { "#{described_class.gitlab_prefix}some_string" }

      it { is_expected.to be_nil }
    end
  end
end
