# frozen_string_literal: true

require 'spec_helper'

describe Projects::ContainerRepository::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  subject { described_class.new(project, user) }

  before do
    stub_container_registry_config(enabled: true)
  end

  context 'when user does not have access to registry' do
    let!(:repository) { create(:container_repository, :root, project: project) }

    it 'does not delete a repository' do
      expect { subject.execute(repository) }.not_to change { ContainerRepository.all.count }
    end
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    context 'when root container repository exists' do
      let!(:repository) { create(:container_repository, :root, project: project) }

      before do
        stub_container_registry_tags(repository: :any, tags: [])
      end

      it 'deletes the repository' do
        expect(repository).to receive(:delete_tags!).and_call_original
        expect { described_class.new(project, user).execute(repository) }.to change { ContainerRepository.all.count }.by(-1)
      end
    end
  end
end
