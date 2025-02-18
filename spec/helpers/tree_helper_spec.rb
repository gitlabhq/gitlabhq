# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeHelper, feature_category: :source_code_management do
  include Devise::Test::ControllerHelpers
  let_it_be(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }

  let_it_be(:user) { create(:user) }

  describe '#tree_edit_branch' do
    let(:ref) { 'main' }

    before do
      allow(helper).to receive(:patch_branch_name).and_return('patch-1')
    end

    it 'returns nil when cannot edit tree' do
      allow(helper).to receive(:can_edit_tree?).and_return(false)
      expect(helper.tree_edit_branch(project, ref)).to be_nil
    end

    it 'returns the patch branch name when can edit tree' do
      allow(helper).to receive(:can_edit_tree?).and_return(true)
      expect(helper.tree_edit_branch(project, ref)).to eq('patch-1')
    end
  end

  describe '#breadcrumb_data_attributes' do
    let(:ref) { 'main' }
    let(:base_attributes) do
      {
        selected_branch: ref,
        can_push_code: 'false',
        can_push_to_branch: 'false',
        can_collaborate: 'false',
        new_blob_path: project_new_blob_path(project, ref),
        upload_path: project_create_blob_path(project, ref),
        new_dir_path: project_create_dir_path(project, ref),
        new_branch_path: new_project_branch_path(project),
        new_tag_path: new_project_tag_path(project),
        can_edit_tree: 'false'
      }
    end

    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@ref, ref)
      allow(helper).to receive(:selected_branch).and_return(ref)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
      allow(helper).to receive(:user_access).and_return(instance_double(Gitlab::UserAccess, can_push_to_branch?: false))
      allow(helper).to receive(:can_collaborate_with_project?).and_return(false)
      allow(helper).to receive(:can_edit_tree?).and_return(false)
    end

    it 'returns a list of breadcrumb attributes' do
      expect(helper.breadcrumb_data_attributes).to eq(base_attributes)
    end
  end

  describe '#compare_path' do
    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@ref, sha)
    end

    context 'when ref is blank' do
      it 'returns nil when root_ref matches ref' do
        expect(helper.compare_path(project, repository, '')).to be_nil
      end

      it 'returns nil when ref is nil' do
        expect(helper.compare_path(project, repository, nil)).to be_nil
      end
    end

    context 'when ref is present' do
      it 'returns compare path when ref differs from root_ref' do
        expected_path = project_compare_index_path(project, from: 'master', to: 'feature-branch')
        expect(helper.compare_path(project, repository, 'feature-branch')).to eq(expected_path)
      end

      it 'returns nil when ref matches root_ref' do
        allow(repository).to receive(:root_ref).and_return('main')
        expect(helper.compare_path(project, repository, 'main')).to be_nil
      end

      it 'handles refs with special characters' do
        expected_path = project_compare_index_path(project, from: 'master', to: 'feature/branch-1')
        expect(helper.compare_path(project, repository, 'feature/branch-1')).to eq(expected_path)
      end
    end
  end

  describe '#vue_tree_header_app_data' do
    let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@ref, sha)
      allow(helper).to receive(:can?).and_return(false)
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      allow(helper).to receive(:user_access).and_return(instance_double(Gitlab::UserAccess, can_push_to_branch?: false))
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:ssh_enabled?).and_return(true)
      allow(helper).to receive(:http_enabled?).and_return(true)
      allow(helper).to receive(:show_xcode_link?).and_return(false)
    end

    subject { helper.vue_tree_header_app_data(project, repository, sha, pipeline) }

    it 'returns a list of attributes related to the project' do
      is_expected.to include(
        project_id: project.id,
        ref: sha,
        ref_type: '',
        breadcrumbs: helper.breadcrumb_data_attributes,
        project_root_path: project_path(project),
        project_path: project.full_path,
        compare_path: project_compare_index_path(project, from: repository&.root_ref, to: sha),
        web_ide_button_options: Gitlab::Json.parse(subject[:web_ide_button_options]).to_json,
        web_ide_button_default_branch: project.default_branch_or_main,
        ssh_url: ssh_clone_url_to_repo(project),
        http_url: http_clone_url_to_repo(project),
        xcode_url: '',
        download_links: helper.download_links(project, sha, "#{project.path}-#{sha.tr('/', '-')}").to_json,
        download_artifacts: '[]',
        escaped_ref: sha
      )
    end

    context 'when ssh is disabled' do
      before do
        allow(helper).to receive(:ssh_enabled?).and_return(false)
      end

      it 'does not include ssh_url' do
        expect(subject[:ssh_url]).to be_empty
      end
    end

    context 'when http is disabled' do
      before do
        allow(helper).to receive(:http_enabled?).and_return(false)
      end

      it 'does not include http_url' do
        expect(subject[:http_url]).to be_empty
      end
    end

    context 'when project is empty' do
      before do
        allow(project).to receive(:empty_repo?).and_return(true)
      end

      it 'does not include download_links' do
        expect(subject[:download_links]).to be_empty
      end
    end

    context 'when pipeline is not present' do
      let(:pipeline) { nil }

      it 'does not include download_artifacts' do
        expect(subject[:download_artifacts]).to be nil
      end
    end
  end

  describe '#vue_file_list_data' do
    it 'returns a list of attributes related to the project' do
      helper.instance_variable_set(:@ref_type, 'heads')
      allow(helper).to receive(:selected_branch).and_return(sha)

      expect(helper.vue_file_list_data(project, sha)).to include(
        project_path: project.full_path,
        project_short_path: project.path,
        ref: sha,
        escaped_ref: sha,
        full_name: project.name_with_namespace,
        ref_type: 'heads',
        target_branch: sha
      )
    end
  end

  describe '#web_ide_button_data' do
    let(:blob) { project.repository.blob_at('refs/heads/master', @path) }

    let_it_be(:user_preferences_gitpod_path) { '/-/profile/preferences#user_gitpod_enabled' }
    let_it_be(:user_profile_enable_gitpod_path) { '/-/user_settings/profile?user%5Bgitpod_enabled%5D=true' }

    before do
      @path = ''
      @project = project
      @ref = sha

      allow(helper).to receive_messages(
        current_user: nil,
        can_collaborate_with_project?: true,
        can?: true,
        user_preferences_gitpod_path: user_preferences_gitpod_path,
        user_profile_enable_gitpod_path: user_profile_enable_gitpod_path
      )
    end

    subject { helper.web_ide_button_data(blob: blob) }

    it 'returns a list of attributes related to the project' do
      expect(subject).to include(
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
        pipeline_editor_url: "/#{project.full_path}/-/ci/editor?branch_name=#{@ref}",

        gitpod_url: '',
        user_preferences_gitpod_path: user_preferences_gitpod_path,
        user_profile_enable_gitpod_path: user_profile_enable_gitpod_path
      )
    end

    context 'a blob is passed' do
      before do
        @path = 'README.md'
      end

      it 'returns edit url and webide url for the blob' do
        expect(subject).to include(
          show_edit_button: true,
          edit_url: "/#{project.full_path}/-/edit/#{sha}/#{@path}",
          web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}/-/#{@path}"
        )
      end

      it 'does not load blob from repository again' do
        blob

        expect(repository).not_to receive(:blob_at)

        subject
      end
    end

    context 'nil blob is passed' do
      let(:blob) { nil }

      it 'does not load blob from repository' do
        expect(repository).not_to receive(:blob_at)

        subject
      end
    end

    context 'user does not have write access but a personal fork exists' do
      include ProjectForksHelper

      let(:project) { create(:project, :repository) }
      let(:forked_project) { create(:project, :repository, namespace: user.namespace) }

      before do
        project.add_guest(user)
        fork_project(project, nil, target_project: forked_project)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'includes forked project path as project_path' do
        expect(subject).to include(
          project_path: forked_project.full_path,
          is_fork: true,
          needs_to_fork: false,
          show_edit_button: false,
          web_ide_url: "/-/ide/project/#{forked_project.full_path}/edit/#{sha}"
        )
      end

      context 'a blob is passed' do
        before do
          @path = 'README.md'
        end

        it 'returns edit url and web ide for the blob in the fork' do
          expect(subject).to include(
            is_blob: true,
            show_edit_button: true,
            # edit urls are automatically redirected to the fork
            edit_url: "/#{project.full_path}/-/edit/#{sha}/#{@path}",
            web_ide_url: "/-/ide/project/#{forked_project.full_path}/edit/#{sha}/-/#{@path}"
          )
        end
      end
    end

    context 'for archived project' do
      before do
        allow(helper).to receive(:can_collaborate_with_project?).and_return(false)
        allow(helper).to receive(:can?).and_return(false)

        project.update!(archived: true)

        @path = 'README.md'
      end

      it 'does not show any buttons' do
        expect(subject).to include(
          is_blob: true,
          show_edit_button: false,
          show_web_ide_button: false,
          show_gitpod_button: false
        )
      end
    end

    context 'user has write access' do
      before do
        project.add_developer(user)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'includes original project path as project_path' do
        expect(subject).to include(
          project_path: project.full_path,

          is_fork: false,
          needs_to_fork: false,

          show_edit_button: false,
          web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}"
        )
      end

      context 'a blob is passed' do
        before do
          @path = 'README.md'
        end

        it 'returns edit url and web ide for the blob in the fork' do
          expect(subject).to include(
            is_blob: true,
            show_edit_button: true,
            edit_url: "/#{project.full_path}/-/edit/#{sha}/#{@path}",
            web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}/-/#{@path}"
          )
        end
      end
    end

    context 'gitpod settings is enabled' do
      before do
        allow(Gitlab::CurrentSettings)
          .to receive(:gitpod_enabled)
          .and_return(true)

        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'has show_gitpod_button: true' do
        expect(subject).to include(
          show_gitpod_button: true
        )
      end

      it 'has gitpod_enabled: true when user has enabled gitpod' do
        user.gitpod_enabled = true

        expect(subject).to include(
          gitpod_enabled: true
        )
      end

      it 'has gitpod_enabled: false when user has not enabled gitpod' do
        user.gitpod_enabled = false

        expect(subject).to include(
          gitpod_enabled: false
        )
      end

      it 'has show_gitpod_button: false when web ide button is not shown' do
        allow(helper).to receive(:can_collaborate_with_project?).and_return(false)
        allow(helper).to receive(:can?).and_return(false)

        expect(subject).to include(
          show_web_ide_button: false,
          show_gitpod_button: false
        )
      end
    end
  end

  describe '.patch_branch_name' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.patch_branch_name('master') }

    it 'returns a patch branch name' do
      freeze_time do
        epoch = Time.now.strftime('%s%L').last(5)

        expect(subject).to eq "#{user.username}-master-patch-#{epoch}"
      end
    end

    context 'without a current_user' do
      let(:user) { nil }

      it 'returns nil' do
        expect(subject).to be nil
      end
    end
  end

  describe '.fork_modal_options' do
    let_it_be(:blob) { project.repository.blob_at('refs/heads/master', @path) }
    let(:fork_path)  { "/#{project.path_with_namespace}/-/forks/new" }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.fork_modal_options(project, blob) }

    it 'returns correct fork path' do
      expect(subject).to match a_hash_including(fork_path: fork_path, fork_modal_id: nil)
    end

    context 'when show_edit_button true' do
      before do
        allow(helper).to receive(:show_edit_button?).and_return(true)
      end

      it 'returns correct fork path and modal id' do
        expect(subject).to match a_hash_including(
          fork_path: fork_path,
          fork_modal_id: 'modal-confirm-fork-edit')
      end
    end

    context 'when show_web_ide_button true' do
      before do
        allow(helper).to receive(:show_web_ide_button?).and_return(true)
      end

      it 'returns correct fork path and modal id' do
        expect(subject).to match a_hash_including(
          fork_path: fork_path,
          fork_modal_id: 'modal-confirm-fork-webide')
      end
    end
  end
end
