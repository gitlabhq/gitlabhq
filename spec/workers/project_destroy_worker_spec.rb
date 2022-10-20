# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectDestroyWorker do
  let(:project) { create(:project, :repository, pending_delete: true) }
  let!(:repository) { project.repository.raw }

  subject { described_class.new }

  describe '#perform' do
    it 'deletes the project' do
      subject.perform(project.id, project.first_owner.id, {})

      expect(Project.all).not_to include(project)
      expect(repository).not_to exist
    end

    it 'does not raise error when project could not be found' do
      expect do
        subject.perform(-1, project.first_owner.id, {})
      end.not_to raise_error
    end

    it 'does not raise error when user could not be found' do
      expect do
        subject.perform(project.id, -1, {})
      end.not_to raise_error
    end
  end
end
