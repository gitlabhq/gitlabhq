# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require 'gitlab/rspec/stub_env'
require_relative '../../../../../../tooling/lib/tooling/events/track_pipeline_events'
require_relative '../../../../../../tooling/lib/tooling/glci/failure_categories/report_job_failure'

RSpec.describe Tooling::Glci::FailureCategories::ReportJobFailure, feature_category: :tooling do
  include StubENV

  let(:job_id)           { '12345'         }
  let(:failure_category) { 'test_failures' }
  let(:track_pipeline_events_instance) { instance_double(Tooling::Events::TrackPipelineEvents, send_event: nil) }

  before do
    stub_env('CI_JOB_ID', nil)

    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).and_return(track_pipeline_events_instance)
  end

  describe '#initialize' do
    context 'when all required parameters are provided' do
      it 'initializes without error' do
        expect do
          described_class.new(job_id: job_id, failure_category: failure_category)
        end.not_to raise_error
      end
    end

    context 'when job_id is provided from environment' do
      before do
        stub_env('CI_JOB_ID', job_id)
      end

      it 'initializes without error using CI_JOB_ID from environment' do
        expect do
          described_class.new(failure_category: failure_category)
        end.not_to raise_error
      end
    end
  end

  describe '#report' do
    subject(:reporter) { described_class.new(job_id: job_id, failure_category: failure_category) }

    it 'sends event with correct attributes' do
      reporter.report

      expect(track_pipeline_events_instance).to have_received(:send_event).with(
        "glci_job_failed",
        label: job_id,
        property: failure_category
      )
    end
  end
end
