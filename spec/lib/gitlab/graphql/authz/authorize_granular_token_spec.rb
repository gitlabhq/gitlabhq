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
      it 'applies the directive with permission and boundary as symbols' do
        test_type.authorize_granular_token permissions: :read_project, boundary: :project

        directive = test_type.directives.first
        expect(directive).to be_a(Directives::Authz::GranularScope)
        expect(directive.arguments[:permissions]).to eq(['read_project'])
        expect(directive.arguments[:boundary]).to eq('project')
        expect(directive.arguments[:boundary_argument]).to be_nil
      end

      it 'applies directive with array of permissions' do
        test_type.authorize_granular_token permissions: [:read_project, :update_project]

        directive = test_type.directives.first
        expect(directive.arguments[:permissions]).to eq(%w[read_project update_project])
      end
    end

    context 'when used on a mutation' do
      it 'applies directive with symbol permission and boundary_argument' do
        test_mutation.authorize_granular_token permissions: :create_issue, boundary_argument: :project_path

        directive = test_mutation.directives.first
        expect(directive).to be_a(Directives::Authz::GranularScope)
        expect(directive.arguments[:permissions]).to eq(['create_issue'])
        expect(directive.arguments[:boundary_argument]).to eq('project_path')
        expect(directive.arguments[:boundary]).to be_nil
      end
    end
  end

  describe '.granular_scope_directive' do
    it 'returns a directive hash with symbol permission and boundary' do
      result = test_type.granular_scope_directive(permissions: :read_project, boundary: :project)

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: ['READ_PROJECT'],
          boundary: 'project'
        }
      })
    end

    it 'returns a directive hash with array of permissions' do
      result = test_type.granular_scope_directive(permissions: [:read_project, :update_project])

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: %w[READ_PROJECT UPDATE_PROJECT]
        }
      })
    end

    it 'returns a directive hash with boundary_argument' do
      result = test_mutation.granular_scope_directive(permissions: :create_issue, boundary_argument: :project_path)

      expect(result).to eq({
        Directives::Authz::GranularScope => {
          permissions: ['CREATE_ISSUE'],
          boundary_argument: 'project_path'
        }
      })
    end
  end
end
