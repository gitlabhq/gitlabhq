# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CompleteNamespaceSettingsMigration, :redis do
  let(:migration) { spy('migration') }

  context 'when still legacy artifacts exist' do
    let(:namespaces) { table(:namespaces) }
    let(:namespace_settings) { table(:namespace_settings) }
    let!(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }

    it 'steals sidekiq jobs from BackfillNamespaceSettings background migration' do
      expect(Gitlab::BackgroundMigration).to receive(:steal).with('BackfillNamespaceSettings')

      migrate!
    end

    it 'migrates namespaces without namespace_settings' do
      expect { migrate! }.to change { namespace_settings.count }.from(0).to(1)
    end
  end
end
