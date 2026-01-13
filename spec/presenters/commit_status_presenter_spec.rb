# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitStatusPresenter do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  subject(:presenter) do
    described_class.new(build)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#callout_failure_message' do
    subject(:callout_failure_message) { presenter.callout_failure_message }

    context 'when troubleshooting doc is available' do
      let(:failure_reason) { :environment_creation_failure }

      before do
        build.failure_reason = failure_reason
      end

      it 'appends the troubleshooting link' do
        is_expected.to eq("#{described_class.callout_failure_messages[failure_reason]} " \
                              "<a href=\"#{help_page_path('ci/environments/_index.md', anchor: 'error-job-would-create-an-environment-with-an-invalid-parameter')}\">How do I fix it?</a>")
      end
    end

    context 'when custom error message is available' do
      let(:failure_reason) { :job_router_failure }

      before do
        build.failure_reason = failure_reason
        build.job_messages.create!(
          content: 'No available executors matching requirements: gpu=true',
          severity: :error,
          project_id: build.project_id,
          partition_id: build.partition_id
        )
      end

      it 'includes the custom message' do
        expect(callout_failure_message).to include('The Job Router failed to run this job.')
        expect(callout_failure_message).to include('No available executors matching requirements: gpu=true')
      end

      it 'formats the message correctly' do
        expect(callout_failure_message).to eq('The Job Router failed to run this job. No available executors matching requirements: gpu=true')
      end
    end

    context 'when custom error message is not available' do
      let(:failure_reason) { :job_router_failure }

      before do
        build.failure_reason = failure_reason
      end

      it 'shows fallback message' do
        expect(callout_failure_message).to eq('The Job Router failed to run this job. Please contact your administrator.')
      end
    end
  end

  describe 'covers all failure reasons' do
    let(:message) { presenter.callout_failure_message }

    CommitStatus.failure_reasons.keys.each do |failure_reason|
      context failure_reason do
        before do
          build.failure_reason = failure_reason
        end

        it "is a valid status" do
          expect { message }.not_to raise_error
        end
      end
    end

    context 'invalid failure message' do
      before do
        expect(build).to receive(:failure_reason) { 'invalid failure message' }
      end

      it "is an invalid status" do
        expect { message }.to raise_error(/key not found:/)
      end
    end
  end
end
