# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetGroupWikiRepositoryStatesIdSequence, feature_category: :geo_replication do
  let(:group_wiki_repository_states_table) { table(:group_wiki_repository_states) }

  around do |example|
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
      Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
        example.run
      end
    end
  end

  def sequence_value
    Gitlab::Database::PostgresSequence.find_by(seq_name: 'group_wiki_repository_states_id_seq').last_value
  end

  describe '#up' do
    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      context 'when group_wiki_repository_states table is empty' do
        it 'advances the sequence to at least 1000' do
          expect(group_wiki_repository_states_table.count).to eq(0)

          migrate!

          expect(sequence_value).to be >= 1000
        end
      end

      context 'when group_wiki_repository_states table has records' do
        let!(:organization) { table(:organizations).create!(name: 'Organization', path: 'organization') }
        let!(:group) do
          table(:namespaces).create!(
            name: 'Namespace', path: 'namespace', type: 'Group', organization_id: organization.id
          )
        end

        let!(:group_wiki_repository) do
          table(:group_wiki_repositories).create!(group_id: group.id, disk_path: 'path/to/wiki')
        end

        # Reproduces the affected instances, where the row's id was set to the group id
        # instead of being drawn from the sequence.
        let!(:group_wiki_repository_state) do
          group_wiki_repository_states_table.create!(
            id: group.id,
            group_id: group.id,
            group_wiki_repository_id: group_wiki_repository.group_id
          )
        end

        it 'advances the sequence to at least MAX(id) + 1000' do
          migrate!

          max_id = group_wiki_repository_states_table.maximum(:id)

          expect(max_id).to be_present
          expect(sequence_value).to be >= max_id + 1000
        end
      end
    end

    context 'when on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'leaves the sequence untouched' do
        expect { migrate! }.not_to change { sequence_value }
      end
    end
  end
end
