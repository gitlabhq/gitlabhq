# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectDestroyWorker, feature_category: :source_code_management do
  let!(:project) { create(:project, :small_repo, pending_delete: true) }
  let!(:repository) { project.repository.raw }

  let(:user) { project.first_owner }
  let(:params) { {} }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [project.id, user.id, {}] }

    it 'does not change projects when run twice' do
      expect { worker.perform(project.id, user.id, {}) }.to change { Project.count }.by(-1)
      expect { worker.perform(project.id, user.id, {}) }.not_to change { Project.count }
    end
  end

  describe '#perform' do
    shared_examples 'deletes the project' do
      specify do
        worker.perform(project.id, user.id, params)

        expect(Project.all).not_to include(project)
        expect(repository).not_to exist
      end
    end

    it_behaves_like 'deletes the project'

    context 'when an admin deletes the project' do
      let_it_be(:user) { create(:admin) }

      context 'with admin_mode setting enabled' do
        context 'with admin mode session', :enable_admin_mode do
          it_behaves_like 'deletes the project'
        end

        context 'without admin mode session' do
          it 'does not delete the project' do
            worker.perform(project.id, user.id, params)

            expect(Project.all).to include(project)
            expect(repository).to exist
          end
        end
      end

      context 'with admin_mode setting disabled' do
        before do
          stub_application_setting(admin_mode: false)
        end

        context 'without admin mode session' do
          it_behaves_like 'deletes the project'
        end
      end
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

  describe 'concurrency limit' do
    it 'overrides the default with a positive application setting' do
      stub_application_setting(project_deletion_jobs_concurrency_limit: 50)

      expect(described_class.get_concurrency_limit).to eq(50)
    end

    it 'falls back to the default calculation when the setting is 0' do
      stub_application_setting(project_deletion_jobs_concurrency_limit: 0)

      expect(described_class).to receive(:calculate_default_limit_from_max_percentage).and_return(42)
      expect(described_class.get_concurrency_limit).to eq(42)
    end
  end
end
