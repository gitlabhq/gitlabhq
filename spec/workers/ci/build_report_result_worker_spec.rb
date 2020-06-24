# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildReportResultWorker do
  subject { described_class.new.perform(build_id) }

  context 'when build exists' do
    let(:build) { create(:ci_build) }
    let(:build_id) { build.id }

    it 'calls build report result service' do
      expect_next_instance_of(Ci::BuildReportResultService) do |build_report_result_service|
        expect(build_report_result_service).to receive(:execute)
      end

      subject
    end
  end

  context 'when build does not exist' do
    let(:build_id) { -1 }

    it 'does not call build report result service' do
      expect(Ci::BuildReportResultService).not_to receive(:execute)

      subject
    end
  end
end
