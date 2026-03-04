# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::AuthorizeGranularToken, feature_category: :permissions do
  let(:test_type) do
    Class.new(Types::BaseObject) do
      graphql_name 'TestType'
    end
  end

  let(:test_mutation) do
    Class.new(Mutations::BaseMutation) do
      graphql_name 'TestMutation'
    end
  end

  describe '.authorize_granular_token' do
    context 'when used on a GraphQL type' do
      it 'applies the directive with permission, boundary, and boundary_type as symbols' do
        test_type.authorize_granular_token permissions: :read_project, boundary: :project, boundary_type: :project

        directive = test_type.directives.first
        expect(directive).to be_a(Directives::Authz::GranularScope)
        expect(directive.arguments[:permissions]).to eq(['read_project'])
        expect(directive.arguments[:boundary]).to eq('project')
        expect(directive.arguments[:boundary_type]).to eq('project')
        expect(directive.arguments[:boundary_argument]).to be_nil
      end

      it 'applies directive with array of permissions' do
        test_type.authorize_granular_token permissions: [:read_project, :update_project], boundary_type: :project

        directive = test_type.directives.first
        expect(directive.arguments[:permissions]).to eq(%w[read_project update_project])
      end
    end

    context 'when boundary is nil' do
      it 'applies directive without boundary' do
        test_type.authorize_granular_token permissions: :read_project, boundary: nil, boundary_type: :project

        directive = test_type.directives.first
        expect(directive.arguments[:permissions]).to eq(['read_project'])
        expect(directive.arguments[:boundary]).to be_nil
        expect(directive.arguments[:boundary_type]).to eq('project')
      end
    end

    context 'when used on a mutation' do
      it 'applies directive with symbol permission and boundary_argument' do
        test_mutation.authorize_granular_token(
          permissions: :create_issue,
          boundary_argument: :project_path,
          boundary_type: :project
        )

        directive = test_mutation.directives.first
        expect(directive).to be_a(Directives::Authz::GranularScope)
        expect(directive.arguments[:permissions]).to eq(['create_issue'])
        expect(directive.arguments[:boundary_argument]).to eq('project_path')
        expect(directive.arguments[:boundary_type]).to eq('project')
        expect(directive.arguments[:boundary]).to be_nil
      end
    end

    context 'with different boundary_type values' do
      it 'applies directive with group boundary_type' do
        test_type.authorize_granular_token permissions: :read_group, boundary: :group, boundary_type: :group

        directive = test_type.directives.first
        expect(directive.arguments[:boundary_type]).to eq('group')
      end

      it 'applies directive with user boundary_type' do
        test_type.authorize_granular_token permissions: :read_user_preference, boundary: :user, boundary_type: :user

        directive = test_type.directives.first
        expect(directive.arguments[:boundary_type]).to eq('user')
      end

      it 'applies directive with instance boundary_type' do
        test_type.authorize_granular_token(
          permissions: :read_snapshot,
          boundary: :instance,
          boundary_type: :instance
        )

        directive = test_type.directives.first
        expect(directive.arguments[:boundary_type]).to eq('instance')
      end
    end
  end

  describe '.granular_scope_directive' do
    it 'returns a directive hash with symbol permission and boundary' do
      result = test_type.granular_scope_directive(
        permissions: :read_project, boundary: :project, boundary_type: :project
      )

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: ['read_project'],
          boundary: 'project',
          boundary_type: 'PROJECT'
        }
      })
    end

    it 'returns a directive hash with array of permissions' do
      result = test_type.granular_scope_directive(
        permissions: [:read_project, :update_project], boundary_type: :project
      )

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: %w[read_project update_project],
          boundary_type: 'PROJECT'
        }
      })
    end

    it 'returns a directive hash with boundary_argument' do
      result = test_mutation.granular_scope_directive(
        permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
      )

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: ['create_issue'],
          boundary_argument: 'project_path',
          boundary_type: 'PROJECT'
        }
      })
    end

    it 'returns a directive hash without boundary_type when boundary_type is nil' do
      result = test_type.granular_scope_directive(
        permissions: :read_project, boundary: :project, boundary_type: nil
      )

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: ['read_project'],
          boundary: 'project'
        }
      })
    end

    it 'raises ArgumentError for invalid permissions' do
      expect do
        test_type.granular_scope_directive(permissions: :not_a_real_permission, boundary_type: :project)
      end.to raise_error(ArgumentError, /Invalid granular scope permission\(s\): not_a_real_permission/)
    end
  end
end
