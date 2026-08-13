# frozen_string_literal: true

require 'spec_helper'

module QueryLogsSpec
  class TestController < ApplicationController
    skip_before_action :authenticate_user!, :check_two_factor_requirement

    def first_user
      User.first
      render body: nil
    end

    def first_ci_pipeline
      Ci::Pipeline.first
      render body: nil
    end

    private

    [:auth_user, :current_user, :signed_in?].each do |method|
      define_method(method) { nil }
    end
  end

  class TestJob
    include Sidekiq::Worker

    def perform
      Gitlab::ApplicationContext.with_context(caller_id: self.class.name) do
        User.first
      end
    end
  end

  class TestMailer < ApplicationMailer
    def first_user
      User.first
    end
  end
end

RSpec.describe 'ActiveRecord::QueryLogs', feature_category: :database do
  describe 'For rails web requests' do
    let(:correlation_id) { SecureRandom.uuid }
    let(:recorded) { ActiveRecord::QueryRecorder.new { make_request(correlation_id, :first_user) } }

    let(:component_map) do
      {
        "application" => "test",
        "endpoint_id" => "QueryLogsSpec::TestController#first_user",
        "correlation_id" => correlation_id,
        "db_config_name" => "main",
        "db_config_database" => 'gitlabhq_test'
      }
    end

    it 'generates a query that includes the component and value' do
      component_map.each do |component, value|
        expect(recorded.log.last).to include("#{component}:#{value}")
      end
    end

    it 'annotates the query with exactly these tags' do
      expect(normalized_tags(recorded.log.last)).to contain_exactly(
        'application:test',
        'correlation_id:CORRELATION_ID',
        'endpoint_id:QueryLogsSpec::TestController#first_user',
        'db_config_database:gitlabhq_test',
        'db_config_name:main',
        'line:LINE'
      )
    end

    it 'reports the line relative to the application root' do
      expect(annotation_for(recorded.log.last)).to match(%r{,line:/\S+\.rb:\d+:in\s+\S})
      expect(recorded.log.last).not_to include(Rails.root.to_s)
    end

    context 'when using CI database' do
      let(:recorded) { ActiveRecord::QueryRecorder.new { make_request(correlation_id, :first_ci_pipeline) } }
      let(:base_component_map) do
        {
          "application" => "test",
          "endpoint_id" => "QueryLogsSpec::TestController#first_ci_pipeline",
          "correlation_id" => correlation_id,
          "db_config_name" => 'ci'
        }
      end

      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      context 'when using multiple databases' do
        let(:component_map) do
          base_component_map.merge({
            "db_config_database" => 'gitlabhq_test_ci'
          })
        end

        before do
          skip_if_shared_database(:ci)
        end

        it 'generates a query that includes the component and value' do
          component_map.each do |component, value|
            expect(recorded.log.last).to include("#{component}:#{value}")
          end
        end
      end

      context 'when using a ci connection to a single database' do
        let(:component_map) do
          base_component_map.merge({
            "db_config_database" => 'gitlabhq_test'
          })
        end

        before do
          skip_if_multiple_databases_not_setup(:ci)
          skip_if_database_exists(:ci)
        end

        it 'generates a query that includes the component and value' do
          component_map.each do |component, value|
            expect(recorded.log.last).to include("#{component}:#{value}")
          end
        end
      end
    end
  end

  describe 'for Sidekiq worker jobs' do
    around do |example|
      with_sidekiq_server_middleware do |chain|
        chain.add Labkit::Middleware::Sidekiq::Context::Server
        chain.add Gitlab::SidekiqMiddleware::QueryLogs
        example.run
      end
    end

    after(:all) do
      QueryLogsSpec::TestJob.clear
    end

    before do
      QueryLogsSpec::TestJob.perform_async
    end

    let(:sidekiq_job) { QueryLogsSpec::TestJob.jobs.first }
    let(:recorded) { ActiveRecord::QueryRecorder.new { QueryLogsSpec::TestJob.drain } }

    let(:component_map) do
      {
        "application" => Gitlab.process_name,
        "endpoint_id" => "QueryLogsSpec::TestJob",
        "correlation_id" => sidekiq_job['correlation_id'],
        "jid" => sidekiq_job['jid'],
        "db_config_name" => "main",
        "db_config_database" => 'gitlabhq_test'
      }
    end

    it 'generates a query that includes the component and value' do
      component_map.each do |component, value|
        expect(recorded.log.last).to include("#{component}:#{value}")
      end
    end

    # The tag list is built once per process, so the application name is
    # resolved at boot rather than per query. Rebuilding it here reproduces
    # what a Sidekiq process ends up with.
    context 'when the tags are built in a Sidekiq process' do
      let!(:tags_were) { ActiveRecord::QueryLogs.tags }

      before do
        allow(Gitlab).to receive(:process_name).and_return('sidekiq')
        ActiveRecord::QueryLogs.tags = Gitlab::QueryLogs.tags
      end

      after do
        ActiveRecord::QueryLogs.tags = tags_were
      end

      it 'annotates the query with exactly these tags' do
        expect(normalized_tags(recorded.log.last)).to contain_exactly(
          'application:sidekiq',
          'correlation_id:CORRELATION_ID',
          'jid:JID',
          'endpoint_id:QueryLogsSpec::TestJob',
          'db_config_database:gitlabhq_test',
          'db_config_name:main',
          'line:LINE'
        )
      end

      it 'does not leak the Active Job :job tag' do
        expect(recorded.log.last).not_to include('job:')
      end
    end

    describe 'for ActionMailer delivery jobs', :sidekiq_mailers do
      let(:delivery_job) { QueryLogsSpec::TestMailer.first_user.deliver_later }

      let(:recorded) do
        ActiveRecord::QueryRecorder.new do
          Sidekiq::Worker.drain_all
        end
      end

      let(:component_map) do
        {
          "application" => Gitlab.process_name,
          "endpoint_id" => "ActionMailer::MailDeliveryJob",
          "jid" => delivery_job.job_id,
          "db_config_name" => "main",
          "db_config_database" => 'gitlabhq_test'
        }
      end

      it 'generates a query that includes the component and value' do
        component_map.each do |component, value|
          expect(recorded.log.last).to include("#{component}:#{value}")
        end
      end
    end
  end

  def annotation_for(sql)
    sql[%r{/\*(.+?)\*/}m, 1]
  end

  # Replaces tag values that legitimately change between runs with placeholders,
  # so one assertion can cover the exact tag set. Order is not asserted: Rails 8
  # sorts the tags alphabetically, Rails 7.2 keeps the configured order.
  def normalized_tags(sql)
    volatile = %w[correlation_id jid line]

    annotation_for(sql).split(',').map do |pair|
      key = pair.partition(':').first

      volatile.include?(key) ? "#{key}:#{key.upcase}" : pair
    end
  end

  def make_request(correlation_id, action_name)
    request_env = Rack::MockRequest.env_for('/')

    ::Labkit::Context.push(caller_id: QueryLogsSpec::TestController.endpoint_id_for_action(action_name))
    ::Labkit::Correlation::CorrelationId.use_id(correlation_id) do
      QueryLogsSpec::TestController.action(action_name).call(request_env)
    end
  end
end
