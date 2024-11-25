# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SetupHelper::Gitaly, feature_category: :gitaly do
  describe '.configuration_toml' do
    let(:gitaly_dir) { GitalySetup.gitaly_dir } # this directory must exist
    let(:storages) { { 'default' => '/the/default/path', 'other' => '/the/other/storage/path' } }
    let(:options) { {} }

    subject(:config) do
      toml = described_class.configuration_toml(gitaly_dir, storages, options)

      Gitlab::Utils::TomlParser.safe_parse(toml)
    end

    it 'generates a gitaly configuration file' do
      expect(config).to include(
        'socket_path' => "#{gitaly_dir}/gitaly.socket",
        'storage' => [
          { 'name' => 'default', 'path' => '/the/default/path' },
          { 'name' => 'other', 'path' => '/the/other/storage/path' }
        ]
      )
    end

    context 'with gitaly_socket option set' do
      let(:options) { { gitaly_socket: 'gitaly2.socket' } }

      it 'generates a gitaly configuration file' do
        expect(config).to include(
          'socket_path' => "#{gitaly_dir}/gitaly2.socket",
          'storage' => [
            { 'name' => 'default', 'path' => '/the/default/path' },
            { 'name' => 'other', 'path' => '/the/other/storage/path' }
          ]
        )
      end
    end

    context 'with more than one configured socket' do
      before do
        stub_storage_settings('default' => {}, 'other' => { 'gitaly_address' => "#{gitaly_dir}/other.socket" })
      end

      it 'aborts with message' do
        expect { config }.to raise_error ArgumentError, 'Your gitlab.yml contains more than one gitaly_address.'
      end
    end

    context 'with a configured non-unix-socket gitaly address' do
      before do
        stub_storage_settings('default' => { 'gitaly_address' => 'tcp://127.0.0.1' })
      end

      it 'aborts with message' do
        expect { config }.to raise_error ArgumentError,
          "Automatic config.toml generation only supports 'unix:' addresses."
      end
    end
  end
end
