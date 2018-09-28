require 'spec_helper'

describe TreeHelper do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:sha) { 'ce369011c189f62c815f5971d096b26759bab0d1' }

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
end
