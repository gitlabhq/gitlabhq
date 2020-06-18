# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

describe Gitlab::Git::RuggedImpl::UseRugged, :seed_helper do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:feature_flag_name) { 'feature-flag-name' }
  let(:temp_gitaly_metadata_file) { create_temporary_gitaly_metadata_file }

  before(:all) do
    create_gitaly_metadata_file
  end

  subject(:wrapper) do
    klazz = Class.new do
      include Gitlab::Git::RuggedImpl::UseRugged

      def rugged_test(ref, test_number)
      end
    end

    klazz.new
  end

  before do
    allow(Gitlab::GitalyClient).to receive(:can_use_disk?).and_call_original
    Gitlab::GitalyClient.instance_variable_set(:@can_use_disk, {})
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

  context 'when feature flag is not persisted' do
    context 'when running puma with multiple threads' do
      before do
        allow(subject).to receive(:running_puma_with_multiple_threads?).and_return(true)
      end

      it 'returns false' do
        expect(subject.use_rugged?(repository, feature_flag_name)).to be false
      end
    end

    context 'when not running puma with multiple threads' do
      before do
        allow(subject).to receive(:running_puma_with_multiple_threads?).and_return(false)
      end

      it 'returns true when gitaly matches disk' do
        expect(subject.use_rugged?(repository, feature_flag_name)).to be true
      end

      it 'returns false when disk access fails' do
        allow(Gitlab::GitalyClient).to receive(:storage_metadata_file_path).and_return("/fake/path/doesnt/exist")

        expect(subject.use_rugged?(repository, feature_flag_name)).to be false
      end

      it "returns false when gitaly doesn't match disk" do
        allow(Gitlab::GitalyClient).to receive(:storage_metadata_file_path).and_return(temp_gitaly_metadata_file)

        expect(subject.use_rugged?(repository, feature_flag_name)).to be_falsey

        File.delete(temp_gitaly_metadata_file)
      end

      it "doesn't lead to a second rpc call because gitaly client should use the cached value" do
        expect(subject.use_rugged?(repository, feature_flag_name)).to be true

        expect(Gitlab::GitalyClient).not_to receive(:filesystem_id)

        subject.use_rugged?(repository, feature_flag_name)
      end
    end
  end

  context 'when feature flag is persisted' do
    it 'returns false when the feature flag is off' do
      Feature.disable(feature_flag_name)

      expect(subject.use_rugged?(repository, feature_flag_name)).to be_falsey
    end

    it "returns true when feature flag is on" do
      Feature.enable(feature_flag_name)

      allow(Gitlab::GitalyClient).to receive(:can_use_disk?).and_return(false)

      expect(subject.use_rugged?(repository, feature_flag_name)).to be true
    end
  end

  describe '#running_puma_with_multiple_threads?' do
    context 'when using Puma' do
      before do
        stub_const('::Puma', class_double('Puma'))
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

      it { is_expected.to be_truthy}
    end

    context 'all features are not enabled' do
      let(:feature_keys) { [:feature_key_3, :feature_key_4] }

      it { is_expected.to be_falsey }
    end

    context 'some feature is enabled' do
      let(:feature_keys) { [:feature_key_4, :feature_key_2] }

      it { is_expected.to be_truthy }
    end
  end

  def create_temporary_gitaly_metadata_file
    tmp = Tempfile.new('.gitaly-metadata')
    gitaly_metadata = {
      "gitaly_filesystem_id" => "some-value"
    }
    tmp.write(gitaly_metadata.to_json)
    tmp.flush
    tmp.close
    tmp.path
  end

  def create_gitaly_metadata_file
    File.open(File.join(SEED_STORAGE_PATH, '.gitaly-metadata'), 'w+') do |f|
      gitaly_metadata = {
        "gitaly_filesystem_id" => SecureRandom.uuid
      }
      f.write(gitaly_metadata.to_json)
    end
  end
end
