# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PersonalAccessTokenGranularScope, feature_category: :system_access do
  describe '#as_json' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    subject(:entity_json) { described_class.new(granular_scope).as_json }

    context 'when the scope targets a project' do
      let_it_be(:granular_scope) do
        create(:granular_scope, boundary: ::Authz::Boundary.for(project), permissions: ['read_job'])
      end

      it 'exposes the project_id and leaves group_id nil' do
        expect(entity_json).to eq(
          access: 'selected_memberships',
          permissions: ['read_job'],
          project_id: project.id,
          group_id: nil
        )
      end

      context 'when a project_ids_by_namespace_id map is passed' do
        subject(:entity_json) do
          described_class.new(granular_scope, project_ids_by_namespace_id: map).as_json
        end

        let(:map) { { granular_scope.namespace_id => project.id } }

        it 'resolves project_id from the map without loading the project association' do
          expect(granular_scope.namespace).not_to receive(:project)

          expect(entity_json).to eq(
            access: 'selected_memberships',
            permissions: ['read_job'],
            project_id: project.id,
            group_id: nil
          )
        end
      end
    end

    context 'when the scope targets a group' do
      let_it_be(:granular_scope) do
        create(:granular_scope, boundary: ::Authz::Boundary.for(group), permissions: ['read_job'])
      end

      it 'exposes the group_id and leaves project_id nil' do
        expect(entity_json).to eq(
          access: 'selected_memberships',
          permissions: ['read_job'],
          project_id: nil,
          group_id: group.id
        )
      end
    end

    context 'when the scope has no namespace' do
      let_it_be(:granular_scope) do
        create(:granular_scope, boundary: ::Authz::Boundary.for(::Authz::GranularScope::Access::INSTANCE),
          permissions: ['read_job'])
      end

      it 'leaves both project_id and group_id nil' do
        expect(entity_json).to eq(
          access: 'instance',
          permissions: ['read_job'],
          project_id: nil,
          group_id: nil
        )
      end
    end
  end
end
