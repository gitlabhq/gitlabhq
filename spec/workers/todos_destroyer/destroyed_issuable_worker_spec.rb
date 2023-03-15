# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::DestroyedIssuableWorker, feature_category: :team_planning do
  let(:job_args) { [1, 'MergeRequest'] }

  it 'calls the Todos::Destroy::DestroyedIssuableService' do
    expect_next_instance_of(::Todos::Destroy::DestroyedIssuableService, *job_args) do |service|
      expect(service).to receive(:execute)
    end

    described_class.new.perform(*job_args)
  end
end
