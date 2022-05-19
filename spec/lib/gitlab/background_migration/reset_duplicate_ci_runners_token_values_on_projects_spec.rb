# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetDuplicateCiRunnersTokenValuesOnProjects, :migration, schema: 20220326161803 do # rubocop:disable Layout/LineLength
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  subject(:background_migration) { described_class.new }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')

    projects.create!(id: 1, namespace_id: 123, runners_token: 'duplicate')
    projects.create!(id: 2, namespace_id: 123, runners_token: 'a-runners-token')
    projects.create!(id: 3, namespace_id: 123, runners_token: 'duplicate-2')
    projects.create!(id: 4, namespace_id: 123, runners_token: nil)
    projects.create!(id: 5, namespace_id: 123, runners_token: 'duplicate-2')
    projects.create!(id: 6, namespace_id: 123, runners_token: 'duplicate')
    projects.create!(id: 7, namespace_id: 123, runners_token: 'another-runners-token')
    projects.create!(id: 8, namespace_id: 123, runners_token: 'another-runners-token')
  end

  describe '#up' do
    it 'nullifies duplicate tokens', :aggregate_failures do
      background_migration.perform(1, 2)
      background_migration.perform(3, 4)

      expect(projects.count).to eq(8)
      expect(projects.all.pluck(:id, :runners_token).to_h).to eq(
        {
          1 => nil,
          2 => 'a-runners-token',
          3 => nil,
          4 => nil,
          5 => 'duplicate-2',
          6 => 'duplicate',
          7 => 'another-runners-token',
          8 => 'another-runners-token'
        })
      expect(projects.pluck(:runners_token).uniq).to match_array [
        nil, 'a-runners-token', 'duplicate', 'duplicate-2', 'another-runners-token'
      ]
    end

    it 'does not touch projects outside id range' do
      expect do
        background_migration.perform(1, 2)
      end.not_to change { projects.where(id: [3..8]).each(&:reload).map(&:updated_at) }
    end
  end
end
