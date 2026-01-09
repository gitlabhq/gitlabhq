# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIdeButtonHelper, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- stubbed models are not allowed to access the database
  let_it_be_with_reload(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- stubbed models are not allowed to access the database

  describe '#show_pipeline_editor_button?' do
    subject(:result) { helper.show_pipeline_editor_button?(project, path) }

    let_it_be(:project) { build(:project) }

    context 'when can view pipeline editor' do
      before do
        allow(helper).to receive(:can_view_pipeline_editor?).and_return(true)
      end

      context 'when path is ci config path' do
        let(:path) { project.ci_config_path_or_default }

        it 'returns true' do
          expect(result).to eq(true)
        end
      end

      context 'when path is not config path' do
        let(:path) { '/' }

        it 'returns false' do
          expect(result).to eq(false)
        end
      end
    end

    context 'when can not view pipeline editor' do
      before do
        allow(helper).to receive(:can_view_pipeline_editor?).and_return(false)
      end

      let(:path) { project.ci_config_path_or_default }

      it 'returns false' do
        expect(result).to eq(false)
      end
    end
  end

  describe '#web_ide_button_data' do
    let(:path) { '' }

    let(:repository) { project.repository }
    let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }
    let(:blob) { project.repository.blob_at('refs/heads/master', path) }

    let_it_be(:user_preferences_gitpod_path) { '/-/profile/preferences#user_gitpod_enabled' }
    let_it_be(:user_profile_enable_gitpod_path) { '/-/user_settings/profile?user%5Bgitpod_enabled%5D=true' }

    before do
      @project = project

      helper.instance_variable_set(:@path, path)
      helper.instance_variable_set(:@ref, sha)

      allow(Current).to receive(:organization).and_return(project.organization)
      allow(helper).to receive_messages(
        current_user: nil,
        can_collaborate_with_project?: true,
        can?: true,
        user_preferences_gitpod_path: user_preferences_gitpod_path,
        user_profile_enable_gitpod_path: user_profile_enable_gitpod_path
      )
    end

    subject(:response) { helper.web_ide_button_data(blob: blob) }

    it 'returns a list of attributes related to the project' do
      expect(response).to include(
        project_path: project.full_path,
        ref: sha,

        is_fork: false,
        needs_to_fork: false,
        gitpod_enabled: false,
        is_blob: false,

        show_edit_button: false,
        show_web_ide_button: true,
        show_gitpod_button: false,
        show_pipeline_editor_button: false,

        edit_url: '',
        web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}",
        pipeline_editor_url: "/#{project.full_path}/-/ci/editor?branch_name=#{sha}",

        gitpod_url: '',
        user_preferences_gitpod_path: user_preferences_gitpod_path,
        user_profile_enable_gitpod_path: user_profile_enable_gitpod_path
      )
    end

    context 'when a blob is passed' do
      let(:path) { 'README.md' }

      it 'returns edit url and webide url for the blob' do
        expect(response).to include(
          show_edit_button: true,
          edit_url: "/#{project.full_path}/-/edit/#{sha}/#{path}",
          web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}/-/#{path}"
        )
      end

      it 'does not load blob from repository again' do
        blob

        expect(repository).not_to receive(:blob_at)

        response
      end
    end

    context 'when nil blob is passed' do
      let(:blob) { nil }

      it 'does not load blob from repository' do
        expect(repository).not_to receive(:blob_at)

        response
      end
    end

    context 'when user does not have write access but a personal fork exists' do
      include ProjectForksHelper

      let(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- stubbed models are not allowed to access the database
      let(:forked_project) { create(:project, :repository, namespace: user.namespace) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- stubbed models are not allowed to access the database

      before do
        project.add_guest(user)
        fork_project(project, nil, target_project: forked_project)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'includes forked project path as project_path' do
        expect(response).to include(
          project_path: forked_project.full_path,
          is_fork: true,
          needs_to_fork: false,
          show_edit_button: false,
          web_ide_url: "/-/ide/project/#{forked_project.full_path}/edit/#{sha}"
        )
      end

      context 'when a blob is passed' do
        let(:path) { 'README.md' }
        let(:blob) { project.repository.blob_at('refs/heads/master', path) }

        it 'returns edit url and web ide for the blob in the fork' do
          expect(response).to include(
            is_blob: true,
            show_edit_button: true,
            # edit urls are automatically redirected to the fork
            edit_url: "/#{project.full_path}/-/edit/#{sha}/#{path}",
            web_ide_url: "/-/ide/project/#{forked_project.full_path}/edit/#{sha}/-/#{path}"
          )
        end
      end
    end

    context 'for archived project' do
      let(:path) { 'README.md' }

      before do
        allow(helper).to receive_messages(
          can_collaborate_with_project?: false,
          can?: false
        )

        project.update!(archived: true)
      end

      it 'does not show any buttons' do
        expect(response).to include(
          is_blob: true,
          show_edit_button: false,
          show_web_ide_button: false,
          show_gitpod_button: false
        )
      end
    end

    context 'when user has write access' do
      before do
        project.add_developer(user)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'includes original project path as project_path' do
        expect(response).to include(
          project_path: project.full_path,

          is_fork: false,
          needs_to_fork: false,

          show_edit_button: false,
          web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}"
        )
      end

      context 'when a blob is passed' do
        let(:path) { 'README.md' }

        it 'returns edit url and web ide for the blob in the fork' do
          expect(response).to include(
            is_blob: true,
            show_edit_button: true,
            edit_url: "/#{project.full_path}/-/edit/#{sha}/#{path}",
            web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}/-/#{path}"
          )
        end
      end
    end

    context 'when ona settings is enabled' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:gitpod_enabled)
          .and_return(true)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'has show_gitpod_button: true' do
        expect(response).to include(
          show_gitpod_button: true
        )
      end

      it 'has gitpod_enabled: true when user has enabled gitpod' do
        user.gitpod_enabled = true

        expect(response).to include(
          gitpod_enabled: true
        )
      end

      it 'has gitpod_enabled: false when user has not enabled gitpod' do
        user.gitpod_enabled = false

        expect(response).to include(
          gitpod_enabled: false
        )
      end

      it 'has show_gitpod_button: false when web ide button is not shown' do
        allow(helper).to receive_messages(
          can_collaborate_with_project?: false,
          can?: false
        )

        expect(response).to include(
          show_web_ide_button: false,
          show_gitpod_button: false
        )
      end
    end
  end

  describe '.fork_modal_options' do
    let(:path) { '' }

    let(:blob) { project.repository.blob_at('refs/heads/master', path) }
    let(:fork_path) { "/#{project.path_with_namespace}/-/forks/new" }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:result) { helper.fork_modal_options(project, blob) }

    it 'returns correct fork path' do
      expect(result).to match a_hash_including(fork_path: fork_path, fork_modal_id: nil)
    end

    context 'when show_edit_button true' do
      before do
        allow(helper).to receive(:show_edit_button?).and_return(true)
      end

      it 'returns correct fork path and modal id' do
        expect(result).to match a_hash_including(
          fork_path: fork_path,
          fork_modal_id: 'modal-confirm-fork-edit')
      end
    end

    context 'when show_web_ide_button true' do
      before do
        allow(helper).to receive(:show_web_ide_button?).and_return(true)
      end

      it 'returns correct fork path and modal id' do
        expect(result).to match a_hash_including(
          fork_path: fork_path,
          fork_modal_id: 'modal-confirm-fork-webide')
      end
    end
  end
end
