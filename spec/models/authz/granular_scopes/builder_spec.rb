# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopes::Builder, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:other_project) { create(:project) }

  let(:allowed) { true }
  let(:boundary_rule) do
    instance_double(Authz::GranularScopes::ReadBoundaryRule,
      allowed_resource?: allowed, personal_projects_namespace: user.namespace)
  end

  let(:permissions) { %w[read_job] }

  describe '#build' do
    subject(:scopes) { described_class.new(inputs, boundary_rule: boundary_rule).build }

    shared_examples 'loads no groups or projects' do
      specify do
        recorder = ActiveRecord::QueryRecorder.new { scopes }

        expect(recorder.log).not_to include(a_string_matching(/FROM "namespaces"|FROM "projects"/))
      end
    end

    context 'with a standalone access level' do
      where(:access) { [:user, :instance, :all_memberships] }

      with_them do
        let(:inputs) { [{ access: access, permissions: permissions }] }

        it 'builds one unsaved scope without a namespace', :aggregate_failures do
          expect(scopes.size).to eq(1)

          scope = scopes.first
          expect(scope).to be_new_record
          expect(scope.access).to eq(access.to_s)
          expect(scope.permissions).to eq(permissions)
          expect(scope.namespace).to be_nil
          expect(scope.organization_id).to be_nil
        end

        it 'does not consult the boundary rule' do
          scopes

          expect(boundary_rule).not_to have_received(:allowed_resource?)
        end

        it_behaves_like 'loads no groups or projects'
      end
    end

    context 'with personal_projects access' do
      let(:inputs) { [{ access: :personal_projects, permissions: permissions }] }

      it 'uses the namespace given by the boundary rule', :aggregate_failures do
        expect(scopes.map(&:namespace)).to eq([user.namespace])
        expect(scopes.first.access).to eq('personal_projects')
      end

      it_behaves_like 'loads no groups or projects'
    end

    context 'with selected_memberships access' do
      let(:inputs) do
        [{ access: :selected_memberships, permissions: permissions, group_ids: [group.id], project_ids: [project.id] }]
      end

      it 'builds one unsaved scope per group and project, groups first', :aggregate_failures do
        expect(scopes.map(&:namespace)).to eq([group, project.project_namespace])
        expect(scopes.map(&:access).uniq).to eq(['selected_memberships'])
        expect(scopes).to all(be_new_record)
      end

      it 'asks the boundary rule once per resource, in order' do
        scopes

        expect(boundary_rule).to have_received(:allowed_resource?).with(group).ordered
        expect(boundary_rule).to have_received(:allowed_resource?).with(project).ordered
      end

      context 'with several groups and projects' do
        let(:inputs) do
          [{ access: :selected_memberships, permissions: permissions,
             group_ids: [group.id, other_group.id], project_ids: [project.id, other_project.id] }]
        end

        it 'builds a scope for each of them', :aggregate_failures do
          # id_in has no ORDER BY, so only the group-then-project split is deterministic
          expect(scopes.first(2).map(&:namespace)).to match_array([group, other_group])
          expect(scopes.last(2).map(&:namespace))
            .to match_array([project.project_namespace, other_project.project_namespace])
        end

        it 'loads each model class in one query, plus one for the project namespaces', :aggregate_failures do
          recorder = ActiveRecord::QueryRecorder.new { scopes }

          expect(recorder.log.grep(/FROM "namespaces" WHERE "namespaces"\."type" = 'Group'/).size).to eq(1)
          expect(recorder.log.grep(/FROM "projects"/).size).to eq(1)
          expect(recorder.log.grep(/FROM "namespaces" WHERE "namespaces"\."type" = 'Project'/).size).to eq(1)
        end
      end

      context 'when an ID matches no record' do
        let(:inputs) do
          [{ access: :selected_memberships, permissions: permissions,
             group_ids: [group.id, non_existing_record_id], project_ids: [non_existing_record_id] }]
        end

        it 'drops it' do
          expect(scopes.map(&:namespace)).to eq([group])
        end
      end

      context 'when the input names no resources' do
        let(:inputs) { [{ access: :selected_memberships, permissions: permissions }] }

        it { is_expected.to be_empty }
      end

      context 'when the boundary rule refuses a resource' do
        let(:allowed) { false }

        it 'raises ResourceNotAllowedError' do
          expect { scopes }.to raise_error(described_class::ResourceNotAllowedError)
        end
      end
    end

    context 'when access is a string, as the REST and GraphQL inputs send it' do
      let(:personal_namespace) { user.namespace }

      where(:access, :expected_namespace) do
        'selected_memberships' | ref(:group)
        'personal_projects'    | ref(:personal_namespace)
        'user'                 | nil
      end

      with_them do
        let(:inputs) { [{ access: access, permissions: permissions, group_ids: [group.id] }] }

        it 'builds the scope for the matching access level' do
          expect(scopes.map(&:namespace)).to eq([expected_namespace])
        end
      end
    end

    context 'with several inputs' do
      let(:inputs) do
        [
          { access: :instance, permissions: permissions },
          { access: :selected_memberships, permissions: permissions, group_ids: [group.id] },
          { access: :user, permissions: permissions }
        ]
      end

      it 'flattens the scopes in input order' do
        expect(scopes.map { |scope| [scope.access, scope.namespace] })
          .to eq([['instance', nil], ['selected_memberships', group], ['user', nil]])
      end

      it 'does not persist anything' do
        expect { scopes }.not_to change { Authz::GranularScope.count }
      end
    end
  end
end
