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
    subject { presenter.callout_failure_message }

    context 'when troubleshooting doc is available' do
      let(:failure_reason) { :environment_creation_failure }

      before do
        build.failure_reason = failure_reason
      end

      it 'appends the troubleshooting link' do
        expect(subject).to eq("#{described_class.callout_failure_messages[failure_reason]} " \
                              "<a href=\"#{help_page_path('ci/environments/_index.md', anchor: 'error-job-would-create-an-environment-with-an-invalid-parameter')}\">How do I fix it?</a>")
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
