# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectDestroyWorker, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, pending_delete: true) }
  let_it_be(:repository) { project.repository.raw }

  let(:user) { project.first_owner }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker' do
    let(:job_args) { [project.id, user.id, {}] }

    it 'does not change projects when run twice' do
      expect { worker.perform(project.id, user.id, {}) }.to change { Project.count }.by(-1)
      expect { worker.perform(project.id, user.id, {}) }.not_to change { Project.count }
    end
  end

  describe '#perform' do
    it 'deletes the project' do
      worker.perform(project.id, user.id, {})

      expect(Project.all).not_to include(project)
      expect(repository).not_to exist
    end

    it 'does not raise error when project could not be found' do
      expect do
        worker.perform(-1, user.id, {})
      end.not_to raise_error
    end

    it 'does not raise error when user could not be found' do
      expect do
        worker.perform(project.id, -1, {})
      end.not_to raise_error
    end
  end
end
