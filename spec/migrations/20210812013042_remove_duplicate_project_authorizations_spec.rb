# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_duplicate_project_authorizations')

RSpec.describe RemoveDuplicateProjectAuthorizations, :migration, feature_category: :authentication_and_authorization do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_authorizations) { table(:project_authorizations) }

  let!(:user_1) { users.create! email: 'user1@example.com', projects_limit: 0 }
  let!(:user_2) { users.create! email: 'user2@example.com', projects_limit: 0 }
  let!(:namespace_1) { namespaces.create! name: 'namespace 1', path: 'namespace1' }
  let!(:namespace_2) { namespaces.create! name: 'namespace 2', path: 'namespace2' }
  let!(:project_1) { projects.create! namespace_id: namespace_1.id }
  let!(:project_2) { projects.create! namespace_id: namespace_2.id }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  describe '#up' do
    subject { migrate! }

    context 'User with multiple projects' do
      before do
        project_authorizations.create! project_id: project_1.id, user_id: user_1.id, access_level: Gitlab::Access::DEVELOPER
        project_authorizations.create! project_id: project_2.id, user_id: user_1.id, access_level: Gitlab::Access::DEVELOPER
      end

      it { expect { subject }.not_to change { ProjectAuthorization.count } }
    end

    context 'Project with multiple users' do
      before do
        project_authorizations.create! project_id: project_1.id, user_id: user_1.id, access_level: Gitlab::Access::DEVELOPER
        project_authorizations.create! project_id: project_1.id, user_id: user_2.id, access_level: Gitlab::Access::DEVELOPER
      end

      it { expect { subject }.not_to change { ProjectAuthorization.count } }
    end

    context 'Same project and user but different access level' do
      before do
        project_authorizations.create! project_id: project_1.id, user_id: user_1.id, access_level: Gitlab::Access::DEVELOPER
        project_authorizations.create! project_id: project_1.id, user_id: user_1.id, access_level: Gitlab::Access::MAINTAINER
        project_authorizations.create! project_id: project_1.id, user_id: user_1.id, access_level: Gitlab::Access::REPORTER
      end

      it { expect { subject }.to change { ProjectAuthorization.count }.from(3).to(1) }

      it 'retains the highest access level' do
        subject

        all_records = ProjectAuthorization.all.to_a
        expect(all_records.count).to eq 1
        expect(all_records.first.access_level).to eq Gitlab::Access::MAINTAINER
      end
    end
  end
end
