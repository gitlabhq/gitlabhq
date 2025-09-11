# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGenerator, :silence_stdout, feature_category: :permissions do
  let(:permission) { 'read_fake_resource' }
  let(:args) { [permission] }
  let(:temp_dir) { Dir.mktmpdir }
  let(:config) { { destination_root: temp_dir } }
  let(:permission_file_path) { File.join(temp_dir, 'config/authz/permissions/fake_resource/read.yml') }

  subject(:run_generator) { described_class.start(args, config) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  context 'when there are no underscores in the permission name' do
    let(:permission) { 'invalid' }
    let(:error_message) { 'Permission must be in the format action_resource[_subresource]' }

    it 'raises an error' do
      expect { run_generator }.to raise_error(SystemExit, error_message).and output("#{error_message}\n").to_stderr
    end
  end

  it 'creates the documentation file with the correct content' do
    run_generator

    expect(File).to exist(permission_file_path)
    mock_file_content = File.read(File.expand_path('./mocks/permission_definition.yml', __dir__))
    file_content = File.read(permission_file_path)
    expect(file_content).to eq(mock_file_content)
  end
end
