require 'spec_helper'

describe Gitlab::ProjectTransfer, lib: true do
  before do
    @root_dir = File.join(Rails.root, "public", "uploads")
    @project_transfer = Gitlab::ProjectTransfer.new
    allow(@project_transfer).to receive(:root_dir).and_return(@root_dir)

    @project_path_was = "test_project_was"
    @project_path = "test_project"
    @namespace_path_was = "test_namespace_was"
    @namespace_path = "test_namespace"
  end

  after do
    FileUtils.rm_rf([
      File.join(@root_dir, @namespace_path),
      File.join(@root_dir, @namespace_path_was)
    ])
  end

  describe '#move_project' do
    it "moves project upload to another namespace" do
      FileUtils.mkdir_p(File.join(@root_dir, @namespace_path_was, @project_path))
      @project_transfer.move_project(@project_path, @namespace_path_was, @namespace_path)

      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end

  describe '#rename_project' do
    it "renames project" do
      FileUtils.mkdir_p(File.join(@root_dir, @namespace_path, @project_path_was))
      @project_transfer.rename_project(@project_path_was, @project_path, @namespace_path)

      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end

  describe '#rename_namespace' do
    it "renames namespace" do
      FileUtils.mkdir_p(File.join(@root_dir, @namespace_path_was, @project_path))
      @project_transfer.rename_namespace(@namespace_path_was, @namespace_path)

      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end
end
