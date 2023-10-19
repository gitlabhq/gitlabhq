# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RuggedImpl::UseRugged, feature_category: :gitaly do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:feature_flag_name) { wrapper.rugged_feature_keys.first }

  subject(:wrapper) do
    klazz = Class.new do
      include Gitlab::Git::RuggedImpl::UseRugged

      def rugged_test(ref, test_number); end
    end

    klazz.new
  end

  describe '#execute_rugged_call', :request_store do
    let(:args) { ['refs/heads/master', 1] }

    before do
      allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    end

    it 'instruments Rugged call' do
      expect(subject).to receive(:rugged_test).with(args)

      subject.execute_rugged_call(:rugged_test, args)

      expect(Gitlab::RuggedInstrumentation.query_count).to eq(1)
      expect(Gitlab::RuggedInstrumentation.list_call_details.count).to eq(1)
    end
  end

  describe '#use_rugged?' do
    it 'returns false' do
      expect(subject.use_rugged?(repository, feature_flag_name)).to be false
    end
  end

  describe '#running_puma_with_multiple_threads?' do
    context 'when using Puma' do
      before do
        stub_const('::Puma', double('puma constant'))
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      end

      it "returns false when Puma doesn't support the cli_config method" do
        allow(::Puma).to receive(:respond_to?).with(:cli_config).and_return(false)

        expect(subject.running_puma_with_multiple_threads?).to be_falsey
      end

      it 'returns false for single thread Puma' do
        allow(::Puma).to receive_message_chain(:cli_config, :options).and_return(max_threads: 1)

        expect(subject.running_puma_with_multiple_threads?).to be false
      end

      it 'returns true for multi-threaded Puma' do
        allow(::Puma).to receive_message_chain(:cli_config, :options).and_return(max_threads: 2)

        expect(subject.running_puma_with_multiple_threads?).to be true
      end
    end

    context 'when not using Puma' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(false)
      end

      it 'returns false' do
        expect(subject.running_puma_with_multiple_threads?).to be false
      end
    end
  end

  describe '#rugged_enabled_through_feature_flag?' do
    subject { wrapper.send(:rugged_enabled_through_feature_flag?) }

    before do
      allow(Feature).to receive(:enabled?).with(:feature_key_1).and_return(true)
      allow(Feature).to receive(:enabled?).with(:feature_key_2).and_return(true)
      allow(Feature).to receive(:enabled?).with(:feature_key_3).and_return(false)
      allow(Feature).to receive(:enabled?).with(:feature_key_4).and_return(false)

      stub_const('Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS', feature_keys)
    end

    context 'no feature keys given' do
      let(:feature_keys) { [] }

      it { is_expected.to be_falsey }
    end

    context 'all features are enabled' do
      let(:feature_keys) { [:feature_key_1, :feature_key_2] }

      it { is_expected.to be_falsey }
    end

    context 'all features are not enabled' do
      let(:feature_keys) { [:feature_key_3, :feature_key_4] }

      it { is_expected.to be_falsey }
    end

    context 'some feature is enabled' do
      let(:feature_keys) { [:feature_key_4, :feature_key_2] }

      it { is_expected.to be_falsey }
    end
  end
end
