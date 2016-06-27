require 'spec_helper'

describe TreeHelper do
  describe 'flatten_tree' do
    let(:project) { create(:project) }

    before do
      @repository = project.repository
      @commit = project.commit("e56497bb")
    end

    context "on a directory containing more than one file/directory" do
      let(:tree_item) { double(name: "files", path: "files") }

      it "should return the directory name" do
        expect(flatten_tree(tree_item)).to match('files')
      end
    end

    context "on a directory containing only one directory" do
      let(:tree_item) { double(name: "foo", path: "foo") }

      it "should return the flattened path" do
        expect(flatten_tree(tree_item)).to match('foo/bar')
      end
    end
  end

  describe '#lock_file_link' do
    let(:path_lock) { create :path_lock }
    let(:path) { path_lock.path }
    let(:user) { path_lock.user }
    let(:project) { path_lock.project }

    it "renders unlock link" do
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:license_allows_file_locks?).and_return(true)
      expect(helper.lock_file_link(project, path)).to match('Unlock')
    end

    it "renders lock link" do
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:license_allows_file_locks?).and_return(true)
      expect(helper.lock_file_link(project, 'app/controller')).to match('Lock')
    end
  end
end
