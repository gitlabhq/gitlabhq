# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Marginalia spec' do
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

  class MarginaliaTestMailer < ApplicationMailer
    def first_user
      User.first
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
    around do |example|
      with_sidekiq_server_middleware do |chain|
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
        "application"       => "sidekiq",
        "job_class"         => "MarginaliaTestJob",
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

  def stub_feature(value)
    stub_feature_flags(marginalia: value)
    Gitlab::Marginalia.set_enabled_from_feature_flag
  end

  def make_request(correlation_id)
    request_env = Rack::MockRequest.env_for('/')

    ::Labkit::Correlation::CorrelationId.use_id(correlation_id) do
      MarginaliaTestController.action(:first_user).call(request_env)
    end
  end
end
