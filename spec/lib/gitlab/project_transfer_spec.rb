# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProjectTransfer do
  before do
    @root_dir = File.join(Rails.root, "public", "uploads")
    @project_transfer = described_class.new
    allow(@project_transfer).to receive(:root_dir).and_return(@root_dir)

    @project_path_was = "test_project_was"
    @project_path = "test_project"
    @namespace_path_was = "test_namespace_was"
    @namespace_path = "test_namespace"
  end

  after do
    FileUtils.rm_rf(
      [
        File.join(@root_dir, @namespace_path),
        File.join(@root_dir, @namespace_path_was)
      ])
  end

  describe '#move_project' do
    it "moves project upload to another namespace" do
      path_to_be_moved = File.join(@root_dir, @namespace_path_was, @project_path)
      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      FileUtils.mkdir_p(path_to_be_moved)

      @project_transfer.move_project(@project_path, @namespace_path_was, @namespace_path)

      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end

  describe '#move_namespace' do
    context 'when moving namespace from root into another namespace' do
      it "moves namespace projects' upload" do
        child_namespace = 'test_child_namespace'
        path_to_be_moved = File.join(@root_dir, child_namespace, @project_path)
        expected_path = File.join(@root_dir, @namespace_path, child_namespace, @project_path)
        FileUtils.mkdir_p(path_to_be_moved)

        @project_transfer.move_namespace(child_namespace, nil, @namespace_path)

        expect(Dir.exist?(expected_path)).to be_truthy
      end
    end

    context 'when moving namespace from one parent to another' do
      it "moves namespace projects' upload" do
        child_namespace = 'test_child_namespace'
        path_to_be_moved = File.join(@root_dir, @namespace_path_was, child_namespace, @project_path)
        expected_path = File.join(@root_dir, @namespace_path, child_namespace, @project_path)
        FileUtils.mkdir_p(path_to_be_moved)

        @project_transfer.move_namespace(child_namespace, @namespace_path_was, @namespace_path)

        expect(Dir.exist?(expected_path)).to be_truthy
      end
    end

    context 'when moving namespace from having a parent to root' do
      it "moves namespace projects' upload" do
        child_namespace = 'test_child_namespace'
        path_to_be_moved = File.join(@root_dir, @namespace_path_was, child_namespace, @project_path)
        expected_path = File.join(@root_dir, child_namespace, @project_path)
        FileUtils.mkdir_p(path_to_be_moved)

        @project_transfer.move_namespace(child_namespace, @namespace_path_was, nil)

        expect(Dir.exist?(expected_path)).to be_truthy
      end
    end
  end

  describe '#rename_project' do
    it "renames project" do
      path_to_be_moved = File.join(@root_dir, @namespace_path, @project_path_was)
      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      FileUtils.mkdir_p(path_to_be_moved)

      @project_transfer.rename_project(@project_path_was, @project_path, @namespace_path)

      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end

  describe '#rename_namespace' do
    it "renames namespace" do
      path_to_be_moved = File.join(@root_dir, @namespace_path_was, @project_path)
      expected_path = File.join(@root_dir, @namespace_path, @project_path)
      FileUtils.mkdir_p(path_to_be_moved)

      @project_transfer.rename_namespace(@namespace_path_was, @namespace_path)

      expect(Dir.exist?(expected_path)).to be_truthy
    end
  end
end
