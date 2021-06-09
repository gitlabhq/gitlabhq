# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::TraceChunks do
  let(:instance_specific_config_file) { "config/redis.trace_chunks.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_TRACE_CHUNKS_CONFIG_FILE" }
  let(:shared_state_config_file) { nil }

  before do
    allow(Gitlab::Redis::SharedState).to receive(:config_file_name).and_return(shared_state_config_file)
  end

  include_examples "redis_shared_examples"

  describe '.config_file_name' do
    subject { described_class.config_file_name }

    let(:rails_root) { Dir.mktmpdir('redis_shared_examples') }

    before do
      # Undo top-level stub of config_file_name because we are testing that method now.
      allow(described_class).to receive(:config_file_name).and_call_original

      allow(described_class).to receive(:rails_root).and_return(rails_root)
      FileUtils.mkdir_p(File.join(rails_root, 'config'))
    end

    after do
      FileUtils.rm_rf(rails_root)
    end

    context 'when there is only a resque.yml' do
      before do
        FileUtils.touch(File.join(rails_root, 'config/resque.yml'))
      end

      it { expect(subject).to eq("#{rails_root}/config/resque.yml") }

      context 'and there is a global env override' do
        before do
          stub_env('GITLAB_REDIS_CONFIG_FILE', 'global override')
        end

        it { expect(subject).to eq('global override') }

        context 'and SharedState has a different config file' do
          let(:shared_state_config_file) { 'shared state config file' }

          it { expect(subject).to eq('shared state config file') }
        end
      end
    end
  end
end
