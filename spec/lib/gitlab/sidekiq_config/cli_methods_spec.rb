# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

describe Gitlab::SidekiqConfig::CliMethods do
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

      context 'when the file contains an array of strings' do
        before do
          stub_contents(['queue_a'], ['queue_b'])
        end

        include_examples 'valid file contents'
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
      ['cronjob:stuck_import_jobs', 'cronjob:stuck_merge_jobs', 'post_receive']
    end

    it 'defaults the value of the second argument to .worker_queues' do
      allow(described_class).to receive(:worker_queues).and_return([])

      expect(described_class.expand_queues(['cronjob']))
        .to contain_exactly('cronjob')

      allow(described_class).to receive(:worker_queues).and_return(worker_queues)

      expect(described_class.expand_queues(['cronjob']))
        .to contain_exactly('cronjob', 'cronjob:stuck_import_jobs', 'cronjob:stuck_merge_jobs')
    end

    it 'expands queue namespaces to concrete queue names' do
      expect(described_class.expand_queues(['cronjob'], worker_queues))
        .to contain_exactly('cronjob', 'cronjob:stuck_import_jobs', 'cronjob:stuck_merge_jobs')
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

  describe '.query_workers' do
    using RSpec::Parameterized::TableSyntax

    let(:queues) do
      [
        {
          name: 'a',
          feature_category: :category_a,
          has_external_dependencies: false,
          latency_sensitive: false,
          resource_boundary: :cpu
        },
        {
          name: 'a_2',
          feature_category: :category_a,
          has_external_dependencies: false,
          latency_sensitive: true,
          resource_boundary: :none
        },
        {
          name: 'b',
          feature_category: :category_b,
          has_external_dependencies: true,
          latency_sensitive: true,
          resource_boundary: :memory
        },
        {
          name: 'c',
          feature_category: :category_c,
          has_external_dependencies: false,
          latency_sensitive: false,
          resource_boundary: :memory
        }
      ]
    end

    context 'with valid input' do
      where(:query, :selected_queues) do
        # feature_category
        'feature_category=category_a' | %w(a a_2)
        'feature_category=category_a,category_c' | %w(a a_2 c)
        'feature_category=category_a|feature_category=category_c' | %w(a a_2 c)
        'feature_category!=category_a' | %w(b c)

        # has_external_dependencies
        'has_external_dependencies=true' | %w(b)
        'has_external_dependencies=false' | %w(a a_2 c)
        'has_external_dependencies=true,false' | %w(a a_2 b c)
        'has_external_dependencies=true|has_external_dependencies=false' | %w(a a_2 b c)
        'has_external_dependencies!=true' | %w(a a_2 c)

        # latency_sensitive
        'latency_sensitive=true' | %w(a_2 b)
        'latency_sensitive=false' | %w(a c)
        'latency_sensitive=true,false' | %w(a a_2 b c)
        'latency_sensitive=true|latency_sensitive=false' | %w(a a_2 b c)
        'latency_sensitive!=true' | %w(a c)

        # name
        'name=a' | %w(a)
        'name=a,b' | %w(a b)
        'name=a,a_2|name=b' | %w(a a_2 b)
        'name!=a,a_2' | %w(b c)

        # resource_boundary
        'resource_boundary=memory' | %w(b c)
        'resource_boundary=memory,cpu' | %w(a b c)
        'resource_boundary=memory|resource_boundary=cpu' | %w(a b c)
        'resource_boundary!=memory,cpu' | %w(a_2)

        # combinations
        'feature_category=category_a&latency_sensitive=true' | %w(a_2)
        'feature_category=category_a&latency_sensitive=true|feature_category=category_c' | %w(a_2 c)
      end

      with_them do
        it do
          expect(described_class.query_workers(query, queues))
            .to match_array(selected_queues)
        end
      end
    end

    context 'with invalid input' do
      where(:query, :error) do
        'feature_category="category_a"' | described_class::InvalidTerm
        'feature_category=' | described_class::InvalidTerm
        'feature_category~category_a' | described_class::InvalidTerm
        'worker_name=a' | described_class::UnknownPredicate
      end

      with_them do
        it do
          expect { described_class.query_workers(query, queues) }
            .to raise_error(error)
        end
      end
    end
  end
end
