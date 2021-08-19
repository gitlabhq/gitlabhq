# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SidekiqConfig::WorkerRouter do
  describe '.queue_name_from_worker_name' do
    using RSpec::Parameterized::TableSyntax

    def create_worker(name, namespace = nil)
      Class.new.tap do |worker|
        worker.define_singleton_method(:name) { name }
        worker.define_singleton_method(:queue_namespace) { namespace }
      end
    end

    where(:worker, :expected_name) do
      create_worker('PagesWorker') | 'pages'
      create_worker('PipelineNotificationWorker') | 'pipeline_notification'
      create_worker('PostReceive') | 'post_receive'
      create_worker('PostReceive', :git) | 'git:post_receive'
      create_worker('PipelineHooksWorker', :pipeline_hooks) | 'pipeline_hooks:pipeline_hooks'
      create_worker('Gitlab::JiraImport::AdvanceStageWorker') | 'jira_import_advance_stage'
      create_worker('Gitlab::PhabricatorImport::ImportTasksWorker', :importer) | 'importer:phabricator_import_import_tasks'
    end

    with_them do
      it 'generates a valid queue name from worker name' do
        expect(described_class.queue_name_from_worker_name(worker)).to eql(expected_name)
      end
    end
  end

  shared_context 'router examples setup' do
    using RSpec::Parameterized::TableSyntax

    let(:worker) do
      Class.new do
        def self.name
          'Gitlab::Foo::BarWorker'
        end

        include ApplicationWorker

        feature_category :feature_a
        urgency :low
        worker_resource_boundary :cpu
        tags :expensive
      end
    end

    where(:routing_rules, :expected_queue) do
      # Default, no configuration
      [] | 'foo_bar'
      # Does not match, fallback to the named queue
      [
        ['feature_category=feature_b|urgency=high', 'queue_a'],
        ['resource_boundary=memory', 'queue_b'],
        ['tags=cheap', 'queue_c']
      ] | 'foo_bar'
      # Match a nil queue, fallback to named queue
      [
        ['feature_category=feature_b|urgency=high', 'queue_a'],
        ['resource_boundary=cpu', nil],
        ['tags=cheap', 'queue_c']
      ] | 'foo_bar'
      # Match an empty string, fallback to named queue
      [
        ['feature_category=feature_b|urgency=high', 'queue_a'],
        ['resource_boundary=cpu', ''],
        ['tags=cheap', 'queue_c']
      ] | 'foo_bar'
      # Match the first rule
      [
        ['feature_category=feature_a|urgency=high', 'queue_a'],
        ['resource_boundary=cpu', 'queue_b'],
        ['tags=cheap', 'queue_c']
      ] | 'queue_a'
      # Match the first rule 2
      [
        ['feature_category=feature_b|urgency=low', 'queue_a'],
        ['resource_boundary=cpu', 'queue_b'],
        ['tags=cheap', 'queue_c']
      ] | 'queue_a'
      # Match the third rule
      [
        ['feature_category=feature_b|urgency=high', 'queue_a'],
        ['resource_boundary=memory', 'queue_b'],
        ['tags=expensive', 'queue_c']
      ] | 'queue_c'
      # Match all, first match wins
      [
        ['feature_category=feature_a|urgency=low', 'queue_a'],
        ['resource_boundary=cpu', 'queue_b'],
        ['tags=expensive', 'queue_c']
      ] | 'queue_a'
      # Match the same rule multiple times, the first match wins
      [
        ['feature_category=feature_a', 'queue_a'],
        ['feature_category=feature_a', 'queue_b'],
        ['feature_category=feature_a', 'queue_c']
      ] | 'queue_a'
      # Match wildcard
      [
        ['feature_category=feature_b|urgency=high', 'queue_a'],
        ['resource_boundary=memory', 'queue_b'],
        ['tags=cheap', 'queue_c'],
        ['*', 'default']
      ] | 'default'
      # Match wildcard at the top of the chain. It makes the following rules useless
      [
        ['*', 'queue_foo'],
        ['feature_category=feature_a|urgency=low', 'queue_a'],
        ['resource_boundary=cpu', 'queue_b'],
        ['tags=expensive', 'queue_c']
      ] | 'queue_foo'
      # Match by generated queue name
      [
        ['name=foo_bar', 'queue_foo'],
        ['feature_category=feature_a|urgency=low', 'queue_a'],
        ['resource_boundary=cpu', 'queue_b'],
        ['tags=expensive', 'queue_c']
      ] | 'queue_foo'
    end
  end

  describe '.global' do
    before do
      described_class.remove_instance_variable(:@global_worker_router) if described_class.instance_variable_defined?(:@global_worker_router)
    end

    after do
      described_class.remove_instance_variable(:@global_worker_router)
    end

    context 'valid routing rules' do
      include_context 'router examples setup'

      with_them do
        before do
          stub_config(sidekiq: { routing_rules: routing_rules })
        end

        it 'routes the worker to the correct queue' do
          expect(described_class.global.route(worker)).to eql(expected_queue)
        end
      end
    end

    context 'invalid routing rules' do
      let(:worker) do
        Class.new do
          def self.name
            'Gitlab::Foo::BarWorker'
          end

          include ApplicationWorker
        end
      end

      before do
        stub_config(sidekiq: { routing_rules: routing_rules })
      end

      context 'invalid routing rules format' do
        let(:routing_rules) { ['feature_category=a'] }

        it 'captures the error and falls back to an empty route' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(be_a(described_class::InvalidRoutingRuleError))

          expect(described_class.global.route(worker)).to eql('foo_bar')
        end
      end

      context 'invalid predicate' do
        let(:routing_rules) { [['invalid_term=a', 'queue_a']] }

        it 'captures the error and falls back to an empty route' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
            be_a(Gitlab::SidekiqConfig::WorkerMatcher::UnknownPredicate)
          )

          expect(described_class.global.route(worker)).to eql('foo_bar')
        end
      end
    end
  end

  describe '#route' do
    context 'valid routing rules' do
      include_context 'router examples setup'

      with_them do
        it 'routes the worker to the correct queue' do
          router = described_class.new(routing_rules)

          expect(router.route(worker)).to eql(expected_queue)
        end
      end
    end

    context 'invalid routing rules' do
      it 'raises an exception' do
        expect { described_class.new(nil) }.to raise_error(described_class::InvalidRoutingRuleError)
        expect { described_class.new(['feature_category=a']) }.to raise_error(described_class::InvalidRoutingRuleError)
        expect { described_class.new([['feature_category=a', 'queue_a', 'queue_b']]) }.to raise_error(described_class::InvalidRoutingRuleError)
        expect do
          described_class.new(
            [
              ['feature_category=a', 'queue_b'],
              ['feature_category=b']
            ]
          )
        end.to raise_error(described_class::InvalidRoutingRuleError)
        expect { described_class.new([['invalid_term=a', 'queue_a']]) }.to raise_error(Gitlab::SidekiqConfig::WorkerMatcher::UnknownPredicate)
      end
    end
  end
end
