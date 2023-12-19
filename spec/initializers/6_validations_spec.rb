# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/6_validations'

RSpec.describe '6_validations' do
  describe 'validate_storages_config' do
    context 'with correct settings' do
      before do
        stub_storage_settings(
          'storage' => {},
          'storage.with_VALID-chars01' => {},
          'gitaly.c.gitlab-prd-164c.internal' => {}
        )
      end

      it 'passes through' do
        expect { validate_storages_config }.not_to raise_error
      end
    end

    context 'with invalid storage names' do
      before do
        stub_storage_settings('name with spaces' => {})
      end

      it 'throws an error' do
        expect { validate_storages_config }.to raise_error('"name with spaces" is not a valid storage name. Please fix this in your gitlab.yml before starting GitLab.')
      end
    end
  end
end
