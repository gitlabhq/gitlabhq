# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Marginalia spec' do
  class MarginaliaTestController < ApplicationController
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

    [:auth_user, :current_user, :set_experimentation_subject_id_cookie, :signed_in?].each do |method|
      define_method(method) {}
    end
  end

  class MarginaliaTestJob
    include Sidekiq::Worker

    def perform
      Gitlab::ApplicationContext.with_context(caller_id: self.class.name) do
        User.first
      end
    end
  end

  class MarginaliaTestMailer < ApplicationMailer
    def first_user
      User.first
    end
  end

  describe 'For rails web requests' do
    let(:correlation_id) { SecureRandom.uuid }
    let(:recorded) { ActiveRecord::QueryRecorder.new { make_request(correlation_id, :first_user) } }

    let(:component_map) do
      {
        "application" => "test",
        "endpoint_id" => "MarginaliaTestController#first_user",
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

    context 'when using CI database' do
      let(:recorded) { ActiveRecord::QueryRecorder.new { make_request(correlation_id, :first_ci_pipeline) } }
      let(:base_component_map) do
        {
          "application" => "test",
          "endpoint_id" => "MarginaliaTestController#first_ci_pipeline",
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
        chain.add Marginalia::SidekiqInstrumentation::Middleware
        Marginalia.application_name = "sidekiq"
        example.run
      end
    end

    after(:all) do
      MarginaliaTestJob.clear
    end

    before do
      MarginaliaTestJob.perform_async
    end

    let(:sidekiq_job) { MarginaliaTestJob.jobs.first }
    let(:recorded) { ActiveRecord::QueryRecorder.new { MarginaliaTestJob.drain } }

    let(:component_map) do
      {
        "application" => "sidekiq",
        "endpoint_id" => "MarginaliaTestJob",
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

    describe 'for ActionMailer delivery jobs', :sidekiq_mailers do
      let(:delivery_job) { MarginaliaTestMailer.first_user.deliver_later }

      let(:recorded) do
        ActiveRecord::QueryRecorder.new do
          Sidekiq::Worker.drain_all
        end
      end

      let(:component_map) do
        {
          "application" => "sidekiq",
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

  def make_request(correlation_id, action_name)
    request_env = Rack::MockRequest.env_for('/')

    ::Labkit::Context.push(caller_id: MarginaliaTestController.endpoint_id_for_action(action_name))
    ::Labkit::Correlation::CorrelationId.use_id(correlation_id) do
      MarginaliaTestController.action(action_name).call(request_env)
    end
  end
end
