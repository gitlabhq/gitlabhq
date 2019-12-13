# frozen_string_literal: true

require 'spec_helper'

describe 'Marginalia spec' do
  class MarginaliaTestController < ActionController::Base
    def first_user
      User.first
      render body: nil
    end
  end

  class MarginaliaTestJob
    include Sidekiq::Worker

    def perform
      User.first
    end
  end

  class MarginaliaTestMailer < BaseMailer
    def first_user
      User.first
    end
  end

  def add_sidekiq_middleware
    # Reference: https://github.com/mperham/sidekiq/wiki/Testing#testing-server-middlewaresidekiq
    # Sidekiq test harness fakes worker without its server middlewares, so include instrumentation to 'Sidekiq::Testing' server middleware.
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Marginalia::SidekiqInstrumentation::Middleware
    end
  end

  def remove_sidekiq_middleware
    Sidekiq::Testing.server_middleware do |chain|
      chain.remove Marginalia::SidekiqInstrumentation::Middleware
    end
  end

  def stub_feature(value)
    allow(Gitlab::Marginalia).to receive(:cached_feature_enabled?).and_return(value)
  end

  def make_request(correlation_id)
    request_env = Rack::MockRequest.env_for('/')

    ::Labkit::Correlation::CorrelationId.use_id(correlation_id) do
      MarginaliaTestController.action(:first_user).call(request_env)
    end
  end

  describe 'For rails web requests' do
    let(:correlation_id) { SecureRandom.uuid }
    let(:recorded) { ActiveRecord::QueryRecorder.new { make_request(correlation_id) } }

    let(:component_map) do
      {
        "application"       => "test",
        "controller"        => "marginalia_test",
        "action"            => "first_user",
        "line"              => "/spec/support/helpers/query_recorder.rb",
        "correlation_id"    => correlation_id
      }
    end

    context 'when the feature is enabled' do
      before do
        stub_feature(true)
      end

      it 'generates a query that includes the component and value' do
        component_map.each do |component, value|
          expect(recorded.log.last).to include("#{component}:#{value}")
        end
      end
    end

    context 'when the feature is disabled' do
      before do
        stub_feature(false)
      end

      it 'excludes annotations in generated queries' do
        expect(recorded.log.last).not_to include("/*")
        expect(recorded.log.last).not_to include("*/")
      end
    end
  end

  describe 'for Sidekiq worker jobs' do
    before(:all) do
      add_sidekiq_middleware

      # Because of faking, 'Sidekiq.server?' does not work so implicitly set application name which is done in config/initializers/0_marginalia.rb
      Marginalia.application_name = "sidekiq"
    end

    after(:all) do
      MarginaliaTestJob.clear
      remove_sidekiq_middleware
    end

    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    before do
      MarginaliaTestJob.perform_async
    end

    let(:sidekiq_job) { MarginaliaTestJob.jobs.first }
    let(:recorded) { ActiveRecord::QueryRecorder.new { MarginaliaTestJob.drain } }

    let(:component_map) do
      {
        "application"       => "sidekiq",
        "job_class"         => "MarginaliaTestJob",
        "line"              => "/spec/support/sidekiq_middleware.rb",
        "correlation_id"    => sidekiq_job['correlation_id'],
        "jid"               => sidekiq_job['jid']
      }
    end

    context 'when the feature is enabled' do
      before do
        stub_feature(true)
      end

      it 'generates a query that includes the component and value' do
        component_map.each do |component, value|
          expect(recorded.log.last).to include("#{component}:#{value}")
        end
      end

      describe 'for ActionMailer delivery jobs' do
        let(:delivery_job) { MarginaliaTestMailer.first_user.deliver_later }

        let(:recorded) do
          ActiveRecord::QueryRecorder.new do
            delivery_job.perform_now
          end
        end

        let(:component_map) do
          {
            "application"  => "sidekiq",
            "line"         => "/lib/gitlab/i18n.rb",
            "jid"          => delivery_job.job_id,
            "job_class"    => delivery_job.arguments.first
          }
        end

        it 'generates a query that includes the component and value' do
          component_map.each do |component, value|
            expect(recorded.log.last).to include("#{component}:#{value}")
          end
        end
      end
    end

    context 'when the feature is disabled' do
      before do
        stub_feature(false)
      end

      it 'excludes annotations in generated queries' do
        expect(recorded.log.last).not_to include("/*")
        expect(recorded.log.last).not_to include("*/")
      end
    end
  end
end
