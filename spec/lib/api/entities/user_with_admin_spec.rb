# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::UserWithAdmin, feature_category: :user_management do
  subject(:serialized_entity) { entity.as_json }

  # :with_namespace is required because EE's UserPublic exposes
  # shared_runners_minutes_limit, which is delegated to namespace without allow_nil.
  let_it_be(:user) { create(:user, :with_namespace) }

  let(:entity) { described_class.new(user) }

  context 'when checking provisioned_by_project_id' do
    it 'returns nil when the user is not provisioned by a project' do
      expect(serialized_entity[:provisioned_by_project_id]).to be_nil
    end

    context 'when the user is a service account provisioned by a project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:user) do
        create(:project_provisioned_user, :service_account, :with_namespace, project: project)
      end

      it 'returns the id of the provisioning project' do
        expect(serialized_entity[:provisioned_by_project_id]).to eq(project.id)
      end
    end
  end
end
