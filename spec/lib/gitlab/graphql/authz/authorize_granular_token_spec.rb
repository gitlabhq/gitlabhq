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

    context 'when boundary is a Proc' do
      let(:boundary_proc) { ->(obj) { obj.repository.container } }

      it 'does not serialize the proc into the directive boundary argument' do
        test_type.authorize_granular_token permissions: :read_repository_tag,
          boundary: boundary_proc,
          boundary_type: :project

        directive = test_type.directives.first
        expect(directive).to be_a(Directives::Authz::GranularScope)
        expect(directive.arguments[:boundary]).to be_nil
        expect(directive.arguments[:boundary_type]).to eq('project')
        expect(directive.arguments[:permissions]).to eq(['read_repository_tag'])
      end

      it 'stores the proc in granular_token_boundary_procs keyed by boundary_type' do
        test_type.authorize_granular_token permissions: :read_repository_tag,
          boundary: boundary_proc,
          boundary_type: :project

        expect(test_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
      end

      it 'stores different procs per boundary_type for multi-boundary support' do
        project_proc = ->(obj) { obj.project }
        group_proc = ->(obj) { obj.group }

        test_type.authorize_granular_token permissions: :read_something,
          boundary: project_proc,
          boundary_type: :project
        test_type.authorize_granular_token permissions: :read_something,
          boundary: group_proc,
          boundary_type: :group

        expect(test_type.granular_token_boundary_procs).to eq({
          'project' => project_proc,
          'group' => group_proc
        })
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

  describe '.granular_token_boundary_procs' do
    it 'returns an empty hash when no procs have been registered' do
      expect(test_type.granular_token_boundary_procs).to eq({})
    end

    context 'when a proc is registered via authorize_granular_token' do
      let(:boundary_proc) { ->(obj) { obj.project } }

      before do
        test_type.authorize_granular_token permissions: :read_something,
          boundary: boundary_proc, boundary_type: :project
      end

      it 'returns the proc keyed by boundary_type string on the defining class' do
        expect(test_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
      end

      context 'when a subclass inherits from the type' do
        let(:child_type) do
          Class.new(test_type) { graphql_name 'TestChildType' }
        end

        it 'inherits the proc from the parent' do
          expect(child_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
        end

        it 'leaves the proc present on the parent' do
          expect(test_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
        end
      end
    end

    context 'when authorize_granular_token with a proc is called inside a concern included block' do
      let(:boundary_proc) { ->(obj) { obj.project } }

      let(:concern) do
        p = boundary_proc
        Module.new do
          extend ActiveSupport::Concern
          included do
            authorize_granular_token permissions: :read_something,
              boundary: p, boundary_type: :project
          end
        end
      end

      let(:including_type) do
        c = concern
        Class.new(Types::BaseObject) do
          graphql_name 'GranularTokenConcernIncludingType'
          include c
        end
      end

      it 'stores the proc on the including class' do
        expect(including_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
      end
    end
  end

  describe '.granular_scope_directive' do
    it 'returns an array with a single directive hash for symbol permission and boundary' do
      result = test_type.granular_scope_directive(
        permissions: :read_project, boundary: :project, boundary_type: :project
      )

      expect(result).to eq([{
        Directives::Authz::GranularScope => {
          permissions: ['read_project'],
          boundary: 'project',
          boundary_type: 'PROJECT'
        }
      }])
    end

    it 'returns an array with a single directive hash for array of permissions' do
      result = test_type.granular_scope_directive(
        permissions: [:read_project, :update_project], boundary_type: :project
      )

      expect(result).to eq([{
        Directives::Authz::GranularScope => {
          permissions: %w[read_project update_project],
          boundary_type: 'PROJECT'
        }
      }])
    end

    it 'returns an array with a single directive hash for boundary_argument' do
      result = test_mutation.granular_scope_directive(
        permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
      )

      expect(result).to eq([{
        Directives::Authz::GranularScope => {
          permissions: ['create_issue'],
          boundary_argument: 'project_path',
          boundary_type: 'PROJECT'
        }
      }])
    end

    it 'returns an array with a single directive hash without boundary_type when boundary_type is nil' do
      result = test_type.granular_scope_directive(
        permissions: :read_project, boundary: :project, boundary_type: nil
      )

      expect(result).to eq([{
        Directives::Authz::GranularScope => {
          permissions: ['read_project'],
          boundary: 'project'
        }
      }])
    end

    context 'when boundary is a Proc' do
      let(:boundary_proc) { ->(obj) { obj.project } }

      it 'stores the proc on self and omits boundary from the directive hash' do
        result = test_type.granular_scope_directive(
          permissions: :read_something, boundary: boundary_proc, boundary_type: :project
        )

        expect(test_type.granular_token_boundary_procs).to eq({ 'project' => boundary_proc })
        expect(result.first[Directives::Authz::GranularScope][:boundary]).to be_nil
        expect(result.first[Directives::Authz::GranularScope][:boundary_type]).to eq('PROJECT')
      end
    end
  end

  describe 'boundaries: validation' do
    shared_examples 'raises on invalid boundaries' do |method|
      it 'raises ArgumentError when an entry is not a Hash' do
        expect do
          test_type.public_send(method, permissions: :read_runner, boundaries: [:not_a_hash])
        end.to raise_error(ArgumentError, /must be a Hash/)
      end

      it 'raises ArgumentError when an entry is missing :boundary_type' do
        expect do
          test_type.public_send(method, permissions: :read_runner, boundaries: [{ boundary: :owner }])
        end.to raise_error(ArgumentError, /boundary_type/)
      end

      it 'does not raise when all entries are valid' do
        expect do
          test_type.public_send(method, permissions: :read_runner,
            boundaries: [{ boundary: :owner, boundary_type: :project }])
        end.not_to raise_error
      end
    end

    describe '.authorize_granular_token' do
      include_examples 'raises on invalid boundaries', :authorize_granular_token
    end

    describe '.granular_scope_directive' do
      include_examples 'raises on invalid boundaries', :granular_scope_directive
    end
  end

  describe 'multi-boundary support' do
    describe '.authorize_granular_token with boundaries:' do
      it 'applies one directive per boundary entry' do
        test_type.authorize_granular_token(
          permissions: :read_runner,
          boundaries: [
            { boundary: :owner, boundary_type: :project },
            { boundary: :owner, boundary_type: :group },
            { boundary: :instance, boundary_type: :instance }
          ]
        )

        directives = test_type.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
        expect(directives.size).to eq(3)

        expect(directives[0].arguments[:boundary]).to eq('owner')
        expect(directives[0].arguments[:boundary_type]).to eq('project')

        expect(directives[1].arguments[:boundary]).to eq('owner')
        expect(directives[1].arguments[:boundary_type]).to eq('group')

        expect(directives[2].arguments[:boundary]).to eq('instance')
        expect(directives[2].arguments[:boundary_type]).to eq('instance')
      end

      it 'shares the same permissions across all boundary directives' do
        test_type.authorize_granular_token(
          permissions: :read_runner,
          boundaries: [
            { boundary: :owner, boundary_type: :project },
            { boundary: :instance, boundary_type: :instance }
          ]
        )

        directives = test_type.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
        expect(directives).to all(satisfy { |d| d.arguments[:permissions] == ['read_runner'] })
      end
    end

    describe '.granular_scope_directive with boundaries:' do
      it 'returns an array of directive hashes' do
        result = test_type.granular_scope_directive(
          permissions: :read_runner,
          boundaries: [
            { boundary_argument: :id, boundary_type: :project },
            { boundary: :instance, boundary_type: :instance }
          ]
        )

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result[0]).to eq({
          Directives::Authz::GranularScope => {
            permissions: ['read_runner'],
            boundary_argument: 'id',
            boundary_type: 'PROJECT'
          }
        })
        expect(result[1]).to eq({
          Directives::Authz::GranularScope => {
            permissions: ['read_runner'],
            boundary: 'instance',
            boundary_type: 'INSTANCE'
          }
        })
      end
    end
  end
end
