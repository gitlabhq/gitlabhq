# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::TrackFailedBuildWorker, feature_category: :static_application_security_testing do
  let_it_be(:build) { create(:ci_build, :failed, :sast_report) }
  let_it_be(:exit_code) { 42 }
  let_it_be(:failure_reason) { "script_failure" }

  subject { described_class.new.perform(build.id, exit_code, failure_reason) }

  describe '#perform' do
    context 'when a build has failed' do
      it 'executes track service' do
        expect(Ci::TrackFailedBuildService)
          .to receive(:new)
          .with(build: build, exit_code: exit_code, failure_reason: failure_reason)
          .and_call_original

        subject
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [build.id, exit_code, failure_reason] }
    end
  end
end
