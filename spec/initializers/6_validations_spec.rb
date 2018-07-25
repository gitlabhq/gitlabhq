require 'spec_helper'
require_relative '../../config/initializers/6_validations.rb'

describe '6_validations' do
  before :all do
    FileUtils.mkdir_p('tmp/tests/paths/a/b/c/d')
    FileUtils.mkdir_p('tmp/tests/paths/a/b/c2')
    FileUtils.mkdir_p('tmp/tests/paths/a/b/d')
  end

  after :all do
    FileUtils.rm_rf('tmp/tests/paths')
  end

  describe 'validate_storages_config' do
    context 'with correct settings' do
      before do
        mock_storages('foo' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/c'), 'bar' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/d'))
      end

      it 'passes through' do
        expect { validate_storages_config }.not_to raise_error
      end
    end

    context 'when one of the settings is incorrect' do
      before do
        mock_storages('foo' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/c', 'failure_count_threshold' => 'not a number'))
      end

      it 'throws an error' do
        expect { validate_storages_config }.to raise_error(/failure_count_threshold/)
      end
    end

    context 'with invalid storage names' do
      before do
        mock_storages('name with spaces' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/c'))
      end

      it 'throws an error' do
        expect { validate_storages_config }.to raise_error('"name with spaces" is not a valid storage name. Please fix this in your gitlab.yml before starting GitLab.')
      end
    end
  end

  def mock_storages(storages)
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
  end
end
