# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StuckMergeJobsWorker, feature_category: :code_review_workflow do
  describe 'perform' do
    let(:worker) { described_class.new }

    it 'calls MergeRequests::UnstickLockedMergeRequestsService#execute' do
      expect_next_instance_of(MergeRequests::UnstickLockedMergeRequestsService) do |svc|
        expect(svc).to receive(:execute)
      end

      worker.perform
    end
  end
end
