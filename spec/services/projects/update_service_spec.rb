require 'spec_helper'

describe Projects::UpdateService, services: true do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }

  describe 'update_by_user' do
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

          expect(result).to eq({ status: :error, message: 'Visibility level unallowed' })
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

  describe 'visibility_level' do
    let(:project) { create(:project, :internal) }
    let(:forked_project) { create(:forked_project_with_submodules, :internal) }

    before do
      forked_project.build_forked_project_link(forked_to_project_id: forked_project.id, forked_from_project_id: project.id)
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

  it 'returns an error result when record cannot be updated' do
    result = update_project(project, admin, { name: 'foo&bar' })

    expect(result).to eq({ status: :error, message: 'Project could not be updated' })
  end

  describe 'repository_storage' do
    let(:admin_user) { create(:user, admin: true) }
    let(:user) { create(:user) }
    let(:project) { create(:project, repository_storage: 'a') }
    let(:opts) { { repository_storage: 'b' } }

    before do
      FileUtils.mkdir('tmp/tests/storage_a')
      FileUtils.mkdir('tmp/tests/storage_b')

      storages = { 'a' => 'tmp/tests/storage_a', 'b' => 'tmp/tests/storage_b' }
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

    expect(result).to eq({ status: :error, message: 'Project could not be updated' })
  end

  def update_project(project, user, opts)
    described_class.new(project, user, opts).execute
  end
end
