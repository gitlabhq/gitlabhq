# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeHelper do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }

  let_it_be(:user) { create(:user) }

  def create_file(filename)
    project.repository.create_file(
      project.creator,
      filename,
      'test this',
      message: "Automatically created file #{filename}",
      branch_name: 'master'
    )
  end

  describe '.render_tree' do
    before do
      @id = sha
      @path = ""
      @project = project
      @lfs_blob_ids = []
    end

    it 'displays all entries without a warning' do
      tree = repository.tree(sha, 'files')

      html = render_tree(tree)

      expect(html).not_to have_selector('.tree-truncated-warning')
    end

    it 'truncates entries and adds a warning' do
      stub_const('TreeHelper::FILE_LIMIT', 1)
      tree = repository.tree(sha, 'files')

      html = render_tree(tree)

      expect(html).to have_selector('.tree-truncated-warning', count: 1)
      expect(html).to have_selector('.tree-item-file-name', count: 1)
    end
  end

  describe '.fast_project_blob_path' do
    it 'generates the same path as project_blob_path' do
      blob_path = repository.tree(sha, 'with space').entries.first.path
      fast_path = fast_project_blob_path(project, blob_path)
      std_path  = project_blob_path(project, blob_path)

      expect(fast_path).to eq(std_path)
    end

    it 'generates the same path with encoded file names' do
      tree = repository.tree(sha, 'encoding')
      blob_path = tree.entries.find { |entry| entry.path == 'encoding/テスト.txt' }.path
      fast_path = fast_project_blob_path(project, blob_path)
      std_path  = project_blob_path(project, blob_path)

      expect(fast_path).to eq(std_path)
    end

    it 'respects a configured relative URL' do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')
      blob_path = repository.tree(sha, '').entries.first.path
      fast_path = fast_project_blob_path(project, blob_path)

      expect(fast_path).to start_with('/gitlab/root')
    end

    it 'encodes files starting with #' do
      filename = '#test-file'
      create_file(filename)

      fast_path = fast_project_blob_path(project, filename)

      expect(fast_path).to end_with('%23test-file')
    end
  end

  describe '.fast_project_tree_path' do
    let(:tree_path) { repository.tree(sha, 'with space').path }
    let(:fast_path) { fast_project_tree_path(project, tree_path) }
    let(:std_path) { project_tree_path(project, tree_path) }

    it 'generates the same path as project_tree_path' do
      expect(fast_path).to eq(std_path)
    end

    it 'respects a configured relative URL' do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab/root')

      expect(fast_path).to start_with('/gitlab/root')
    end

    it 'encodes files starting with #' do
      filename = '#test-file'
      create_file(filename)

      fast_path = fast_project_tree_path(project, filename)

      expect(fast_path).to end_with('%23test-file')
    end
  end

  describe 'flatten_tree' do
    let(:tree) { repository.tree(sha, 'files') }
    let(:root_path) { 'files' }
    let(:tree_item) { tree.entries.find { |entry| entry.path == path } }

    subject { flatten_tree(root_path, tree_item) }

    context "on a directory containing more than one file/directory" do
      let(:path) { 'files/html' }

      it "returns the directory name" do
        expect(subject).to match('html')
      end
    end

    context "on a directory containing only one directory" do
      let(:path) { 'files/flat' }

      it "returns the flattened path" do
        expect(subject).to match('flat/path/correct')
      end

      context "with a nested root path" do
        let(:root_path) { 'files/flat' }

        it "returns the flattened path with the root path suffix removed" do
          expect(subject).to match('path/correct')
        end
      end
    end

    context 'when the root path contains a plus character' do
      let(:root_path) { 'gtk/C++' }
      let(:tree_item) { double(flat_path: 'gtk/C++/glade') }

      it 'returns the flattened path' do
        expect(subject).to eq('glade')
      end
    end
  end

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

    before do
      @path = ''
      @project = project
      @ref = sha

      allow(helper).to receive(:current_user).and_return(nil)
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      allow(helper).to receive(:can?).and_return(true)
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

        edit_url: '',
        web_ide_url: "/-/ide/project/#{project.full_path}/edit/#{sha}",
        gitpod_url: ''
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
    end

    context 'user does not have write access but a personal fork exists' do
      include ProjectForksHelper

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

    context 'gitpod feature is enabled' do
      before do
        stub_feature_flags(gitpod: true)
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
