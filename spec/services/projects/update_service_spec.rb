require 'spec_helper'

describe Projects::UpdateService, '#execute' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let(:project) do
    create(:empty_project, creator: user, namespace: user.namespace)
  end

  context 'when changing visibility level' do
    context 'when visibility_level is INTERNAL' do
      it 'updates the project to internal' do
        result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)

        expect(result).to eq({ status: :success })
        expect(project).to be_internal
      end
    end

    context 'when visibility_level is PUBLIC' do
      it 'updates the project to public' do
        result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        expect(result).to eq({ status: :success })
        expect(project).to be_public
      end
    end

    context 'when visibility levels are restricted to PUBLIC only' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when visibility_level is INTERNAL' do
        it 'updates the project to internal' do
          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          expect(result).to eq({ status: :success })
          expect(project).to be_internal
        end
      end

      context 'when visibility_level is PUBLIC' do
        it 'does not update the project to public' do
          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
          expect(project).to be_private
        end

        context 'when updated by an admin' do
          it 'updates the project to public' do
            result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            expect(result).to eq({ status: :success })
            expect(project).to be_public
          end
        end
      end
    end
  end

  describe 'when updating project that has forks' do
    let(:project) { create(:empty_project, :internal) }
    let(:forked_project) { create(:forked_project_with_submodules, :internal) }

    before do
      forked_project.build_forked_project_link(forked_to_project_id: forked_project.id,
                                               forked_from_project_id: project.id)
      forked_project.save
    end

    it 'updates forks visibility level when parent set to more restrictive' do
      opts = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }

      expect(project).to be_internal
      expect(forked_project).to be_internal

      expect(update_project(project, admin, opts)).to eq({ status: :success })

      expect(project).to be_private
      expect(forked_project.reload).to be_private
    end

    it 'does not update forks visibility level when parent set to less restrictive' do
      opts = { visibility_level: Gitlab::VisibilityLevel::PUBLIC }

      expect(project).to be_internal
      expect(forked_project).to be_internal

      expect(update_project(project, admin, opts)).to eq({ status: :success })

      expect(project).to be_public
      expect(forked_project.reload).to be_internal
    end
  end

  context 'when updating a default branch' do
    let(:project) { create(:project, :repository) }

    it 'changes a default branch' do
      update_project(project, admin, default_branch: 'feature')

      expect(Project.find(project.id).default_branch).to eq 'feature'
    end
  end

  context 'when updating a project that contains container images' do
    before do
      stub_container_registry_config(enabled: true)
      stub_container_registry_tags(repository: /image/, tags: %w[rc1])
      create(:container_repository, project: project, name: :image)
    end

    it 'does not allow to rename the project' do
      result = update_project(project, admin, path: 'renamed')

      expect(result).to include(status: :error)
      expect(result[:message]).to match(/contains container registry tags/)
    end

    it 'allows to update other settings' do
      result = update_project(project, admin, public_builds: true)

      expect(result[:status]).to eq :success
      expect(project.reload.public_builds).to be true
    end
  end

  context 'when passing invalid parameters' do
    it 'returns an error result when record cannot be updated' do
      result = update_project(project, admin, { name: 'foo&bar' })

      expect(result).to eq({ status: :error,
                             message: 'Project could not be updated!' })
    end
  end

  describe 'repository_storage' do
    let(:admin_user) { create(:user, admin: true) }
    let(:user) { create(:user) }
    let(:project) { create(:project, repository_storage: 'a') }
    let(:opts) { { repository_storage: 'b' } }

    before do
      FileUtils.mkdir('tmp/tests/storage_a')
      FileUtils.mkdir('tmp/tests/storage_b')

      storages = {
        'a' => { 'path' => 'tmp/tests/storage_a' },
        'b' => { 'path' => 'tmp/tests/storage_b' }
      }
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    after do
      FileUtils.rm_rf('tmp/tests/storage_a')
      FileUtils.rm_rf('tmp/tests/storage_b')
    end

    it 'calls the change repository storage method if the storage changed' do
      expect(project).to receive(:change_repository_storage).with('b')

      update_project(project, admin_user, opts).inspect
    end

    it "doesn't call the change repository storage for non-admin users" do
      expect(project).not_to receive(:change_repository_storage)

      update_project(project, user, opts).inspect
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }
    let(:project) { create(:empty_project, repository_size_limit: 0) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to be_nil
      end
    end
  end

  it 'returns an error result when record cannot be updated' do
    result = update_project(project, admin, { name: 'foo&bar' })

    expect(result).to eq({ status: :error, message: 'Project could not be updated!' })
  end

  def update_project(project, user, opts)
    described_class.new(project, user, opts).execute
  end
end
