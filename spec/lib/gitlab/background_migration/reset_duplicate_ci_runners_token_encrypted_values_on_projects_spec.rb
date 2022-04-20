# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects, :migration, schema: 20220326161803 do # rubocop:disable Layout/LineLength
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:perform) { described_class.new.perform(1, 4) }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')

    projects.create!(id: 1, namespace_id: 123, runners_token_encrypted: 'duplicate')
    projects.create!(id: 2, namespace_id: 123, runners_token_encrypted: 'a-runners-token')
    projects.create!(id: 3, namespace_id: 123, runners_token_encrypted: 'duplicate')
    projects.create!(id: 4, namespace_id: 123, runners_token_encrypted: nil)
    projects.create!(id: 5, namespace_id: 123, runners_token_encrypted: 'duplicate-2')
    projects.create!(id: 6, namespace_id: 123, runners_token_encrypted: 'duplicate-2')
  end

  describe '#up' do
    before do
      stub_const("#{described_class}::SUB_BATCH_SIZE", 2)
    end

    it 'nullifies duplicate tokens', :aggregate_failures do
      perform

      expect(projects.count).to eq(6)
      expect(projects.all.pluck(:id, :runners_token_encrypted).to_h).to eq(
        { 1 => nil, 2 => 'a-runners-token', 3 => nil, 4 => nil, 5 => 'duplicate-2', 6 => 'duplicate-2' }
      )
      expect(projects.pluck(:runners_token_encrypted).uniq).to match_array [nil, 'a-runners-token', 'duplicate-2']
    end
  end
end
