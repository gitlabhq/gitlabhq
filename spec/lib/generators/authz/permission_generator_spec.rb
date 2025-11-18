# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGenerator, :silence_stdout, feature_category: :permissions do
  let(:permission) { 'read_fake_resource' }
  let(:args) { [permission] }
  let(:temp_dir) { Dir.mktmpdir }
  let(:options) { {} }
  let(:config) { { destination_root: temp_dir } }
  let(:permission_file_path) { File.join(temp_dir, 'config/authz/permissions/fake_resource/read.yml') }

  subject(:run_generator) { described_class.new(args, options, config).invoke_all }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  shared_examples 'generating a permission definition' do |mock_file|
    it 'creates the documentation file with the correct content' do
      run_generator

      expect(File).to exist(permission_file_path)
      mock_file_content = File.read(File.expand_path(mock_file, __dir__))
      file_content = File.read(permission_file_path)
      expect(file_content).to eq(mock_file_content)
    end
  end

  it_behaves_like 'generating a permission definition', './mocks/permission_definition.yml'

  context 'with options' do
    let(:permission) { 'read_fake_test_resource' }

    context 'when the action and resource is supplied' do
      let(:options) { { 'action' => 'read_fake', 'resource' => 'resource' } }
      let(:permission_file_path) { File.join(temp_dir, 'config/authz/permissions/resource/read_fake.yml') }

      it_behaves_like 'generating a permission definition', './mocks/permission_definition_override_all.yml'
    end

    context 'when only the action is supplied' do
      let(:options) { { 'action' => 'read_fake' } }
      let(:permission_file_path) { File.join(temp_dir, 'config/authz/permissions/test_resource/read_fake.yml') }

      it_behaves_like 'generating a permission definition', './mocks/permission_definition_override_action.yml'
    end

    context 'when only the resource is supplied' do
      let(:options) { { 'resource' => 'resource' } }
      let(:permission_file_path) { File.join(temp_dir, 'config/authz/permissions/resource/read_fake_test.yml') }

      it_behaves_like 'generating a permission definition', './mocks/permission_definition_override_resource.yml'
    end
  end

  context 'when there are no underscores in the permission name' do
    let(:permission) { 'invalid' }
    let(:error_message) { 'Permission must be in the format action_resource[_subresource]' }

    it 'raises an error' do
      expect { run_generator }.to raise_error(SystemExit, error_message).and output("#{error_message}\n").to_stderr
    end
  end
end
