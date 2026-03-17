# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::LeavePoolRepositoryWorker, feature_category: :gitaly do
  let_it_be(:pool_repository) { create(:pool_repository, :ready) }
  let_it_be(:project) { create(:project, :repository, pool_repository: pool_repository) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'calls leave_pool_repository on the project' do
      expect_next_found_instance_of(Project) do |proj|
        expect(proj).to receive(:leave_pool_repository)
      end

      worker.perform(project.id)
    end

    context 'when project does not exist' do
      it 'does not raise an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [project.id] }

    it 'calls leave_pool_repository' do
      expect_next_found_instance_of(Project) do |proj|
        expect(proj).to receive(:leave_pool_repository)
      end.twice

      perform_multiple(job_args)
    end
  end
end
