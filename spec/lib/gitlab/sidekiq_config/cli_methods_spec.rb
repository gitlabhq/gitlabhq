# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqConfig::CliMethods do
  let(:dummy_root) { '/tmp/' }

  describe '.worker_queues' do
    def expand_path(path)
      File.join(dummy_root, path)
    end

    def stub_exists(exists: true)
      ['app/workers/all_queues.yml', 'ee/app/workers/all_queues.yml'].each do |path|
        allow(File).to receive(:exist?).with(expand_path(path)).and_return(exists)
      end
    end

    def stub_contents(foss_queues, ee_queues)
      allow(YAML).to receive(:load_file)
                       .with(expand_path('app/workers/all_queues.yml'))
                       .and_return(foss_queues)

      allow(YAML).to receive(:load_file)
                       .with(expand_path('ee/app/workers/all_queues.yml'))
                       .and_return(ee_queues)
    end

    before do
      described_class.clear_memoization!
    end

    context 'when the file exists' do
      before do
        stub_exists(exists: true)
      end

      shared_examples 'valid file contents' do
        it 'memoizes the result' do
          result = described_class.worker_queues(dummy_root)

          stub_exists(exists: false)

          expect(described_class.worker_queues(dummy_root)).to eq(result)
        end

        it 'flattens and joins the contents' do
          expected_queues = %w[queue_a queue_b]
          expected_queues = expected_queues.first(1) unless Gitlab.ee?

          expect(described_class.worker_queues(dummy_root))
            .to match_array(expected_queues)
        end
      end

      context 'when the file contains an array of hashes' do
        before do
          stub_contents([{ name: 'queue_a' }], [{ name: 'queue_b' }])
        end

        include_examples 'valid file contents'
      end
    end

    context 'when the file does not exist' do
      before do
        stub_exists(exists: false)
      end

      it 'returns an empty array' do
        expect(described_class.worker_queues(dummy_root)).to be_empty
      end
    end
  end

  describe '.expand_queues' do
    let(:worker_queues) do
      [
        'cronjob:import_stuck_project_import_jobs',
        'cronjob:jira_import_stuck_jira_import_jobs',
        'cronjob:stuck_merge_jobs',
        'post_receive'
      ]
    end

    it 'defaults the value of the second argument to .worker_queues' do
      allow(described_class).to receive(:worker_queues).and_return([])

      expect(described_class.expand_queues(['cronjob']))
        .to contain_exactly('cronjob')

      allow(described_class).to receive(:worker_queues).and_return(worker_queues)

      expect(described_class.expand_queues(['cronjob']))
        .to contain_exactly(
          'cronjob',
          'cronjob:import_stuck_project_import_jobs',
          'cronjob:jira_import_stuck_jira_import_jobs',
          'cronjob:stuck_merge_jobs'
        )
    end

    it 'expands queue namespaces to concrete queue names' do
      expect(described_class.expand_queues(['cronjob'], worker_queues))
        .to contain_exactly(
          'cronjob',
          'cronjob:import_stuck_project_import_jobs',
          'cronjob:jira_import_stuck_jira_import_jobs',
          'cronjob:stuck_merge_jobs'
        )
    end

    it 'lets concrete queue names pass through' do
      expect(described_class.expand_queues(['post_receive'], worker_queues))
        .to contain_exactly('post_receive')
    end

    it 'lets unknown queues pass through' do
      expect(described_class.expand_queues(['unknown'], worker_queues))
        .to contain_exactly('unknown')
    end
  end

  describe '.query_queues' do
    let(:worker_metadatas) do
      [
        {
          name: 'a',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :low,
          resource_boundary: :cpu,
          tags: [:no_disk_io, :git_access]
        },
        {
          name: 'a:2',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :high,
          resource_boundary: :none,
          tags: [:git_access]
        },
        {
          name: 'b',
          feature_category: :category_b,
          has_external_dependencies: true,
          urgency: :high,
          resource_boundary: :memory,
          tags: [:no_disk_io]
        },
        {
          name: 'c',
          feature_category: :category_c,
          has_external_dependencies: false,
          urgency: :throttled,
          resource_boundary: :memory,
          tags: []
        }
      ]
    end

    let(:worker_matcher) { double(:WorkerMatcher) }
    let(:query) { 'feature_category=category_a,category_c' }

    before do
      allow(::Gitlab::SidekiqConfig::WorkerMatcher).to receive(:new).with(query).and_return(worker_matcher)
      allow(worker_matcher).to receive(:match?).and_return(true, true, false, true)
    end

    it 'returns the queue names of matched workers' do
      expect(described_class.query_queues(query, worker_metadatas)).to match(%w(a a:2 c))
    end
  end
end
