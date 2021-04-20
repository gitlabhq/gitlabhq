# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/6_validations'

RSpec.describe '6_validations' do
  describe 'validate_storages_config' do
    context 'with correct settings' do
      before do
        mock_storages('foo' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/c'), 'bar' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/paths/a/b/d'))
      end

      it 'passes through' do
        expect { validate_storages_config }.not_to raise_error
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
