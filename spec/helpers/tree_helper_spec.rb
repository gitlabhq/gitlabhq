require 'spec_helper'

describe TreeHelper do
  describe 'flatten_tree' do
    let(:project) { create(:project) }

    before {
      @repository = project.repository
      @commit = project.repository.commit("e56497bb")
    }

    context "on a directory containing more than one file/directory" do
      let(:tree_item) { double(name: "files", path: "files") }

      it "should return the directory name" do
        flatten_tree(tree_item).should match('files')
      end
    end

    context "on a directory containing only one directory" do
      let(:tree_item) { double(name: "foo", path: "foo") }

      it "should return the flattened path" do
        flatten_tree(tree_item).should match('foo/bar')
      end
    end
  end
end
