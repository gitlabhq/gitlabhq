# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DestroyRollbackService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  let(:repository) { project.repository }
  let(:repository_storage) { project.repository_storage }

  subject { described_class.new(project, user, {}).execute }

  describe '#execute' do
    let(:path) { repository.disk_path + '.git' }
    let(:removal_path) { "#{repository.disk_path}+#{project.id}#{Repositories::DestroyService::DELETED_FLAG}.git" }

    before do
      aggregate_failures do
        expect(TestEnv.storage_dir_exists?(repository_storage, path)).to be_truthy
        expect(TestEnv.storage_dir_exists?(repository_storage, removal_path)).to be_falsey
      end

      # Don't run sidekiq to check if renamed repository exists
      Sidekiq::Testing.fake! { destroy_project(project, user, {}) }

      aggregate_failures do
        expect(TestEnv.storage_dir_exists?(repository_storage, path)).to be_falsey
        expect(TestEnv.storage_dir_exists?(repository_storage, removal_path)).to be_truthy
      end
    end

    it 'restores the repositories' do
      Sidekiq::Testing.fake! { subject }

      aggregate_failures do
        expect(TestEnv.storage_dir_exists?(repository_storage, path)).to be_truthy
        expect(TestEnv.storage_dir_exists?(repository_storage, removal_path)).to be_falsey
      end
    end
  end

  def destroy_project(project, user, params = {})
    Projects::DestroyService.new(project, user, params).execute
  end
end
