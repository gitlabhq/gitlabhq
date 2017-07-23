require 'spec_helper'

describe Gitlab::HealthChecks::FsShardsCheck do
  def command_exists?(command)
    _, status = Gitlab::Popen.popen(%W{ #{command} 1 echo })
    status == 0
  rescue Errno::ENOENT
    false
  end

  def timeout_command
    @timeout_command ||=
      if command_exists?('timeout')
        'timeout'
      elsif command_exists?('gtimeout')
        'gtimeout'
      else
        ''
      end
  end

  let(:metric_class) { Gitlab::HealthChecks::Metric }
  let(:result_class) { Gitlab::HealthChecks::Result }
  let(:repository_storages) { [:default] }
  let(:tmp_dir) { Dir.mktmpdir }

  let(:storages_paths) do
    {
      default: { path: tmp_dir }
    }.with_indifferent_access
  end

  before do
    allow(described_class).to receive(:repository_storages) { repository_storages }
    allow(described_class).to receive(:storages_paths) { storages_paths }
    stub_const('Gitlab::HealthChecks::FsShardsCheck::TIMEOUT_EXECUTABLE', timeout_command)
  end

  after do
    FileUtils.remove_entry_secure(tmp_dir) if Dir.exist?(tmp_dir)
  end

  shared_examples 'filesystem checks' do
    describe '#readiness' do
      subject { described_class.readiness }

      context 'storage points to not existing folder' do
        let(:storages_paths) do
          {
            default: { path: 'tmp/this/path/doesnt/exist' }
          }.with_indifferent_access
        end

        it { is_expected.to include(result_class.new(false, 'cannot stat storage', shard: :default)) }
      end

      context 'storage points to directory that has both read and write rights' do
        before do
          FileUtils.chmod_R(0755, tmp_dir)
        end

        it { is_expected.to include(result_class.new(true, nil, shard: :default)) }

        it 'cleans up files used for testing' do
          expect(described_class).to receive(:storage_write_test).with(any_args).and_call_original

          subject

          expect(Dir.entries(tmp_dir).count).to eq(2)
        end

        context 'read test fails' do
          before do
            allow(described_class).to receive(:storage_read_test).with(any_args).and_return(false)
          end

          it { is_expected.to include(result_class.new(false, 'cannot read from storage', shard: :default)) }
        end

        context 'write test fails' do
          before do
            allow(described_class).to receive(:storage_write_test).with(any_args).and_return(false)
          end

          it { is_expected.to include(result_class.new(false, 'cannot write to storage', shard: :default)) }
        end
      end
    end

    describe '#metrics' do
      subject { described_class.metrics }

      context 'storage points to not existing folder' do
        let(:storages_paths) do
          {
            default: { path: 'tmp/this/path/doesnt/exist' }
          }.with_indifferent_access
        end

        # Unsolved intermittent failure in CI https://gitlab.com/gitlab-org/gitlab-ce/issues/31128
        around(:each) do |example| # rubocop:disable RSpec/AroundBlock
          times_to_try = ENV['CI'] ? 4 : 1
          example.run_with_retry retry: times_to_try
        end

        it 'provides metrics' do
          expect(subject).to all(have_attributes(labels: { shard: :default }))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_accessible, value: 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_readable, value: 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_writable, value: 0))

          expect(subject).to include(an_object_having_attributes(name: :filesystem_access_latency_seconds, value: be >= 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_read_latency_seconds, value: be >= 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_write_latency_seconds, value: be >= 0))
        end
      end

      context 'storage points to directory that has both read and write rights' do
        before do
          FileUtils.chmod_R(0755, tmp_dir)
        end

        it 'provides metrics' do
          expect(subject).to all(have_attributes(labels: { shard: :default }))

          expect(subject).to include(an_object_having_attributes(name: :filesystem_accessible, value: 1))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_readable, value: 1))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_writable, value: 1))

          expect(subject).to include(an_object_having_attributes(name: :filesystem_access_latency_seconds, value: be >= 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_read_latency_seconds, value: be >= 0))
          expect(subject).to include(an_object_having_attributes(name: :filesystem_write_latency_seconds, value: be >= 0))
        end
      end
    end
  end

  context 'when timeout kills fs checks' do
    before do
      stub_const('Gitlab::HealthChecks::FsShardsCheck::COMMAND_TIMEOUT', '1')

      allow(described_class).to receive(:exec_with_timeout).and_wrap_original { |m| m.call(%w(sleep 60)) }
      FileUtils.chmod_R(0755, tmp_dir)
    end

    describe '#readiness' do
      subject { described_class.readiness }

      it { is_expected.to include(result_class.new(false, 'cannot stat storage', shard: :default)) }
    end

    describe '#metrics' do
      subject { described_class.metrics }

      it 'provides metrics' do
        expect(subject).to all(have_attributes(labels: { shard: :default }))

        expect(subject).to include(an_object_having_attributes(name: :filesystem_accessible, value: 0))
        expect(subject).to include(an_object_having_attributes(name: :filesystem_readable, value: 0))
        expect(subject).to include(an_object_having_attributes(name: :filesystem_writable, value: 0))

        expect(subject).to include(an_object_having_attributes(name: :filesystem_access_latency_seconds, value: be >= 0))
        expect(subject).to include(an_object_having_attributes(name: :filesystem_read_latency_seconds, value: be >= 0))
        expect(subject).to include(an_object_having_attributes(name: :filesystem_write_latency_seconds, value: be >= 0))
      end
    end
  end

  context 'when popen always finds required binaries' do
    before do
      allow(described_class).to receive(:exec_with_timeout).and_wrap_original do |method, *args, &block|
        begin
          method.call(*args, &block)
        rescue RuntimeError, Errno::ENOENT
          raise 'expected not to happen'
        end
      end

      stub_const('Gitlab::HealthChecks::FsShardsCheck::COMMAND_TIMEOUT', '10')
    end

    it_behaves_like 'filesystem checks'
  end

  context 'when popen never finds required binaries' do
    before do
      allow(Gitlab::Popen).to receive(:popen).and_raise(Errno::ENOENT)
    end

    it_behaves_like 'filesystem checks'
  end
end
