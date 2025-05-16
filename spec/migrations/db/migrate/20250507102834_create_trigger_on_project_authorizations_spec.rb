# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateTriggerOnProjectAuthorizations, 'write duplication',
  feature_category: :permissions,
  migration: :gitlab_main do
  let(:src_table) { table(:project_authorizations) }
  let(:dest_table) { table(:project_authorizations_for_migration) }

  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:user) { users.create!(username: 'foo', email: 'foo@bar.com', projects_limit: 0) }
  let(:organization) { organizations.create!(name: 'foo', path: 'foo') }
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

  describe 'INSERT' do
    subject(:insert!) { src_table.create!(values) }

    before do
      migrate!
    end

    context 'without destination row' do
      specify do
        expect { insert! }.to change { src_table.count }.from(0).to(1)
      end

      specify do
        expect { insert! }.to change { dest_table.count }.from(0).to(1)
      end

      specify do
        insert!

        expect(dest_table.last!.attributes).to match_array(values.stringify_keys)
      end
    end

    context 'with destination row' do
      before do
        dest_table.create!(values.merge(access_level: maintainer_access))
      end

      specify do
        expect { insert! }.to change { src_table.count }.from(0).to(1)
      end

      specify do
        expect { insert! }.not_to change { dest_table.count }.from(1)
      end

      specify do
        expect { insert! }.to change { dest_table.last!.access_level }.from(maintainer_access).to(developer_access)
      end
    end
  end

  describe 'UPDATE' do
    subject(:update!) { src_table.last!.update!(access_level: maintainer_access) }

    context 'without destination row' do
      before do
        src_table.create!(values)

        migrate!
      end

      specify do
        expect { update! }.not_to change { src_table.count }.from(1)
      end

      specify do
        expect { update! }.to change { dest_table.count }.from(0).to(1)
      end

      specify do
        expect { update! }.to change { dest_table.last&.access_level }.from(nil).to(maintainer_access)
      end
    end

    context 'with destination row' do
      before do
        migrate!

        src_table.create!(values)
      end

      specify do
        expect { update! }.not_to change { src_table.count }.from(1)
      end

      specify do
        expect { update! }.not_to change { dest_table.count }.from(1)
      end

      specify do
        expect { update! }.to change { dest_table.last!.access_level }.from(developer_access).to(maintainer_access)
      end
    end
  end

  describe 'DELETE' do
    subject(:delete!) { src_table.last!.delete }

    context 'without destination row' do
      before do
        src_table.create!(values)

        migrate!
      end

      specify do
        expect { delete! }.to change { src_table.count }.from(1).to(0)
      end

      specify do
        expect { delete! }.not_to change { dest_table.count }.from(0)
      end
    end

    context 'with destination row' do
      before do
        migrate!

        src_table.create!(values)
      end

      specify do
        expect { delete! }.to change { src_table.count }.from(1).to(0)
      end

      specify do
        expect { delete! }.to change { dest_table.count }.from(1).to(0)
      end
    end
  end
end
