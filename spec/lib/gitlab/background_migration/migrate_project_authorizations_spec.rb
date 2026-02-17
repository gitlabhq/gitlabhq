# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateProjectAuthorizations, '#perform', feature_category: :user_management do
  let(:connection) { ApplicationRecord.connection }

  let(:src_table) { table(:project_authorizations) }
  let(:dest_table) { table(:project_authorizations_for_migration) }

  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'foo', path: 'foo') }
  let(:user) do
    users.create!(username: 'foo', email: 'foo@bar.com', projects_limit: 0, organization_id: organization.id)
  end

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }

  let(:project) do
    projects.create!(
      name: 'foo',
      path: 'foo',
      project_namespace_id: namespace.id,
      namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let(:developer_access) { Gitlab::Access::DEVELOPER }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  let(:values) { { user_id: user.id, project_id: project.id, access_level: developer_access } }

  let(:start_cursor) { [0, 0, 0] }
  let(:end_cursor) { [src_table.maximum(:user_id), src_table.maximum(:project_id), src_table.maximum(:access_level)] }

  let!(:src_row) { src_table.create!(values) }

  let(:migration) do
    described_class.new(
      connection: connection,
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :project_authorizations,
      batch_column: :user_id,
      sub_batch_size: 10,
      pause_ms: 0
    )
  end

  subject(:perform) { migration.perform }

  context 'without destination row' do
    before do
      dest_table.where(values).delete_all
    end

    specify do
      expect { perform }.to change { dest_table.count }.from(0).to(1)
    end

    specify do
      perform

      expect(dest_table.last!.attributes).to match_array(values.stringify_keys)
    end

    context 'with varying access levels' do
      before do
        src_table.create!(values.merge(access_level: maintainer_access))
        dest_table.where(values.merge(access_level: maintainer_access)).delete_all
      end

      specify do
        expect { perform }.to change { dest_table.count }.from(0).to(1)
      end

      it 'writes lowest access level' do
        perform

        expect(dest_table.last!.access_level).to be(developer_access)
      end
    end
  end

  context 'with destination row' do
    before do
      dest_table.where(values).update!(access_level: maintainer_access)
    end

    specify do
      expect { perform }.not_to change { dest_table.count }.from(1)
    end

    it 'does not overwrite' do
      perform

      expect(dest_table.last!.access_level).to be(maintainer_access)
    end
  end
end
