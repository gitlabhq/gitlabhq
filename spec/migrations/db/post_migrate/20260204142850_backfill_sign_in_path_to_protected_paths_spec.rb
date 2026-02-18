# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillSignInPathToProtectedPaths, feature_category: :system_access do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when protected_paths_for_get_request does not contain /users/sign_in_path' do
      it 'adds /users/sign_in_path to protected_paths_for_get_request' do
        setting = application_settings.create!(protected_paths_for_get_request: [])

        migrate!

        setting.reload
        expect(setting.protected_paths_for_get_request).to include('/users/sign_in_path')
        expect(setting.protected_paths_for_get_request.count('/users/sign_in_path')).to eq(1)
      end
    end

    context 'when protected_paths_for_get_request already contains /users/sign_in_path' do
      it 'does not duplicate /users/sign_in_path' do
        setting = application_settings.create!(protected_paths_for_get_request: ['/users/sign_in_path'])

        migrate!

        setting.reload
        expect(setting.protected_paths_for_get_request.count('/users/sign_in_path')).to eq(1)
      end
    end

    context 'when protected_paths_for_get_request has custom paths' do
      it 'preserves existing paths and adds /users/sign_in_path' do
        custom_paths = ['/custom/path', '/another/path']
        setting = application_settings.create!(protected_paths_for_get_request: custom_paths)

        migrate!

        setting.reload
        expect(setting.protected_paths_for_get_request).to include('/custom/path')
        expect(setting.protected_paths_for_get_request).to include('/another/path')
        expect(setting.protected_paths_for_get_request).to include('/users/sign_in_path')
      end
    end
  end

  describe '#down' do
    it 'removes /users/sign_in_path from protected_paths_for_get_request' do
      setting = application_settings.create!(protected_paths_for_get_request: [])

      migrate!

      setting.reload
      expect(setting.protected_paths_for_get_request).to include('/users/sign_in_path')

      schema_migrate_down!

      setting.reload
      expect(setting.protected_paths_for_get_request).not_to include('/users/sign_in_path')
    end
  end
end
