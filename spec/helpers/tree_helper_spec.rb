# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeHelper do
  include Devise::Test::ControllerHelpers
  let_it_be(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }

  let_it_be(:user) { create(:user) }

  describe '#commit_in_single_accessible_branch' do
    it 'escapes HTML from the branch name' do
      helper.instance_variable_set(:@branch_name, "<script>alert('escape me!');</script>")
      escaped_branch_name = '&lt;script&gt;alert(&#39;escape me!&#39;);&lt;/script&gt;'

      expect(helper.commit_in_single_accessible_branch).to include(escaped_branch_name)
    end
  end

  describe '#vue_file_list_data' do
    it 'returns a list of attributes related to the project' do
      expect(helper.vue_file_list_data(project, sha)).to include(
        project_path: project.full_path,
        project_short_path: project.path,
        ref: sha,
        escaped_ref: sha,
        full_name: project.name_with_namespace
      )
    end
  end

  describe '#web_ide_button_data' do
    let(:blob) { project.repository.blob_at('refs/heads/master', @path) }

    let_it_be(:user_preferences_gitpod_path) { '/-/profile/preferences#user_gitpod_enabled' }
    let_it_be(:user_profile_enable_gitpod_path) { '/-/profile?user%5Bgitpod_enabled%5D=true' }

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
end
