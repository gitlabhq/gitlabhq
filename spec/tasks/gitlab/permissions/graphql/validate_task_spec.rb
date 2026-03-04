# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Graphql::ValidateTask, feature_category: :permissions do
  let(:task) { described_class.new }

  # Helper to create a mock directive
  def mock_directive(permissions:, boundary_type:)
    instance_double(
      Directives::Authz::GranularScope,
      arguments: {
        permissions: Array(permissions).map(&:to_s).map(&:upcase),
        boundary_type: boundary_type.to_s
      }
    ).tap do |d|
      allow(d).to receive(:is_a?) { |klass| klass == Directives::Authz::GranularScope }
    end
  end

  # Helper to create a mock GraphQL object type
  def mock_type(name, directive: nil, fields: nil)
    directives = directive ? [directive] : []

    type = Object.new
    type.define_singleton_method(:name) { name }
    type.define_singleton_method(:kind) { type }
    type.define_singleton_method(:object?) { true }
    type.define_singleton_method(:directives) { directives }

    if fields
      type.define_singleton_method(:respond_to?) { |method, *| %i[kind directives fields].include?(method) }
      type.define_singleton_method(:fields) { fields }
    else
      type.define_singleton_method(:respond_to?) { |method, *| %i[kind directives].include?(method) }
    end

    type
  end

  # Helper to create a mock field with optional directive
  def mock_field(directive: nil)
    directives = directive ? [directive] : []

    field = Object.new
    field.define_singleton_method(:respond_to?) { |method, *| %i[directives].include?(method) }
    field.define_singleton_method(:directives) { directives }

    field
  end

  # Helper to create a mock mutation resolver
  def mock_resolver(graphql_name:, directive: nil)
    klass = Class.new(Mutations::BaseMutation) do
      self.graphql_name = graphql_name
    end

    allow(klass).to receive(:directives).and_return([directive]) if directive

    klass
  end

  # Helper to create a mock mutation field on the Mutation type
  def mock_mutation_field(resolver:, directive: nil)
    directives = directive ? [directive] : []

    field = Object.new
    field.define_singleton_method(:respond_to?) { |method, *| %i[resolver_class directives].include?(method) }
    field.define_singleton_method(:resolver_class) { resolver }
    field.define_singleton_method(:directives) { directives }

    field
  end

  # Minimal Mutation type mock with no fields
  def empty_mutation_type
    type = Object.new
    type.define_singleton_method(:kind) { type }
    type.define_singleton_method(:object?) { true }
    type.define_singleton_method(:directives) { [] }
    type.define_singleton_method(:fields) { {} }
    type
  end

  describe '#json_schema_file' do
    it 'returns nil' do
      expect(task.send(:json_schema_file)).to be_nil
    end
  end

  describe '#resolve_mutation_class' do
    context 'when field responds to :resolver but not :resolver_class' do
      it 'falls back to the resolver method' do
        resolver_class = Class.new(Mutations::BaseMutation)
        field = Object.new
        field.define_singleton_method(:respond_to?) { |method, *| [:resolver].include?(method) }
        field.define_singleton_method(:resolver) { resolver_class }

        expect(task.send(:resolve_mutation_class, field)).to eq(resolver_class)
      end
    end

    context 'when field responds to :mutation but not :resolver_class or :resolver' do
      it 'falls back to the mutation method' do
        resolver_class = Class.new(Mutations::BaseMutation)
        field = Object.new
        field.define_singleton_method(:respond_to?) { |method, *| [:mutation].include?(method) }
        field.define_singleton_method(:mutation) { resolver_class }

        expect(task.send(:resolve_mutation_class, field)).to eq(resolver_class)
      end
    end

    context 'when resolver is not a BaseMutation subclass' do
      it 'returns nil' do
        field = Object.new
        field.define_singleton_method(:respond_to?) { |method, *| [:resolver_class].include?(method) }
        field.define_singleton_method(:resolver_class) { String }

        expect(task.send(:resolve_mutation_class, field)).to be_nil
      end
    end

    context 'when field does not respond to any resolver method' do
      it 'returns nil' do
        field = Object.new
        field.define_singleton_method(:respond_to?) { |_, *| false }

        expect(task.send(:resolve_mutation_class, field)).to be_nil
      end
    end
  end

  describe '#find_mutation_directive' do
    context 'when directive is on the field' do
      it 'returns the directive from the field without checking the resolver' do
        directive = mock_directive(permissions: :read_project, boundary_type: :project)
        field = mock_field(directive: directive)
        resolver = mock_resolver(graphql_name: 'TestMutation')

        expect(task.send(:find_mutation_directive, field, resolver)).to eq(directive)
      end
    end

    context 'when field does not respond to :directives' do
      it 'checks the resolver for directives' do
        directive = mock_directive(permissions: :read_project, boundary_type: :project)
        field = Object.new
        field.define_singleton_method(:respond_to?) { |_, *| false }
        resolver = mock_resolver(graphql_name: 'TestMutation', directive: directive)

        expect(task.send(:find_mutation_directive, field, resolver)).to eq(directive)
      end
    end
  end

  describe '#validate_boundary_type' do
    context 'when boundary_type is nil' do
      it 'returns without adding a violation' do
        expect do
          task.send(:validate_boundary_type, { kind: 'type', name: 'Test' }, :read_project, nil)
        end.not_to change { task.send(:violations)[:boundary_mismatch].length }
      end
    end

    context 'when assignables are empty' do
      it 'returns without adding a violation' do
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([])

        expect do
          task.send(:validate_boundary_type, { kind: 'type', name: 'Test' }, :read_project, :project)
        end.not_to change { task.send(:violations)[:boundary_mismatch].length }
      end
    end
  end

  describe '#format_boundary_mismatch_errors' do
    it 'returns empty string when there are no violations' do
      expect(task.send(:format_boundary_mismatch_errors)).to eq('')
    end
  end

  describe '#run', :unlimited_max_formatted_output_length do
    subject(:run) { task.run }

    before do
      allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => empty_mutation_type })
    end

    context 'when there are no directives' do
      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when types include introspection and non-object types' do
      let(:introspection_type) do
        type = Object.new
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type
      end

      let(:payload_type) do
        type = Object.new
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          '__Schema' => introspection_type,
          'CreateIssuePayload' => payload_type,
          'Mutation' => empty_mutation_type
        )
      end

      it 'skips introspection and payload types' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has valid permissions and boundary_type' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:type) { mock_type('ProjectType', directive: directive) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'ProjectType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has a boundary_type not matching assignable permission boundaries' do
      let(:directive) { mock_directive(permissions: :read_something, boundary_type: :user) }
      let(:type) { mock_type('SomethingType', directive: directive) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'SomethingType' => type, 'Mutation' => empty_mutation_type
        )
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error with boundary details' do
        expect { run }.to raise_error(SystemExit).and output(
          /\[type\] SomethingType: read_something.*Directive boundary_type: user/m
        ).to_stdout
      end
    end

    context 'when a type has a valid boundary_type matching one of the assignable boundaries' do
      let(:directive) { mock_directive(permissions: :read_something, boundary_type: :project) }
      let(:type) { mock_type('SomethingType', directive: directive) }
      let(:mock_assignable) do
        instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group user])
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'SomethingType' => type, 'Mutation' => empty_mutation_type
        )
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a mutation has a directive with valid boundary_type' do
      let(:directive) { mock_directive(permissions: :create_issue, boundary_type: :project) }
      let(:resolver) { mock_resolver(graphql_name: 'CreateIssue', directive: directive) }
      let(:mutation_field) { mock_mutation_field(resolver: resolver) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }
      let(:mutation_type) do
        fields = { 'createIssue' => mutation_field }
        type = Object.new
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields].include?(method) }
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type.define_singleton_method(:fields) { fields }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:create_issue).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a mutation resolver has no GranularScope directive' do
      let(:resolver) { mock_resolver(graphql_name: 'NoDirectiveMutation') }
      let(:mutation_field) { mock_mutation_field(resolver: resolver) }
      let(:mutation_type) do
        fields = { 'noDirectiveMutation' => mutation_field }
        type = Object.new
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields].include?(method) }
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type.define_singleton_method(:fields) { fields }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => mutation_type })
      end

      it 'skips the mutation and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a mutation resolver does not respond to graphql_name' do
      let(:directive) { mock_directive(permissions: :create_issue, boundary_type: :project) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }
      let(:mutation_type) do
        resolver_class = Class.new(Mutations::BaseMutation)
        allow(resolver_class).to receive(:respond_to?).and_call_original
        allow(resolver_class).to receive(:respond_to?).with(:graphql_name).and_return(false)
        allow(resolver_class).to receive(:directives).and_return([directive])

        field = Object.new
        field.define_singleton_method(:respond_to?) { |method, *| %i[resolver_class directives].include?(method) }
        field.define_singleton_method(:resolver_class) { resolver_class }
        field.define_singleton_method(:directives) { [] }

        type = Object.new
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields].include?(method) }
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type.define_singleton_method(:fields) { { 'createIssue' => field } }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:create_issue).and_return([mock_assignable])
      end

      it 'uses the camelized field name and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a mutation has a mismatched boundary_type' do
      let(:directive) { mock_directive(permissions: :create_issue, boundary_type: :instance) }
      let(:resolver) { mock_resolver(graphql_name: 'CreateIssue', directive: directive) }
      let(:mutation_field) { mock_mutation_field(resolver: resolver) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group]) }
      let(:mutation_type) do
        fields = { 'createIssue' => mutation_field }
        type = Object.new
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields].include?(method) }
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type.define_singleton_method(:fields) { fields }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:create_issue).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(
          /\[mutation\] CreateIssue: create_issue.*Directive boundary_type: instance/m
        ).to_stdout
      end
    end

    context 'when a field has a directive with valid boundary_type' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:field) { mock_field(directive: directive) }
      let(:type) { mock_type('QueryType', fields: { 'project' => field }) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'QueryType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a field has directives but no GranularScope directive' do
      let(:field_without_granular_scope) { mock_field }
      let(:type) { mock_type('QueryType', fields: { 'project' => field_without_granular_scope }) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'QueryType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'skips the field and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type directive has nil boundary_type' do
      let(:directive) do
        instance_double(
          Directives::Authz::GranularScope,
          arguments: {
            permissions: ['READ_PROJECT'],
            boundary_type: nil
          }
        ).tap do |d|
          allow(d).to receive(:is_a?) { |klass| klass == Directives::Authz::GranularScope }
        end
      end

      let(:type) { mock_type('ProjectType', directive: directive) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'ProjectType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'completes successfully without validating boundary' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a mutation field has a non-BaseMutation resolver' do
      let(:mutation_type) do
        field = Object.new
        field.define_singleton_method(:respond_to?) { |method, *| %i[resolver_class directives].include?(method) }
        field.define_singleton_method(:resolver_class) { String }
        field.define_singleton_method(:directives) { [] }

        type = Object.new
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { [] }
        type.define_singleton_method(:fields) { { 'notAMutation' => field } }
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields].include?(method) }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => mutation_type })
      end

      it 'skips the field and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has fields that do not respond to :directives' do
      let(:field_without_directives) do
        field = Object.new
        field.define_singleton_method(:respond_to?) { |_, *| false }
        field
      end

      let(:type) { mock_type('SomeType', fields: { 'someField' => field_without_directives }) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'SomeType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'skips the field and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has valid boundary_type but permission has no assignable groups' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:type) { mock_type('ProjectType', directive: directive) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'ProjectType' => type, 'Mutation' => empty_mutation_type
        )
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a field has a mismatched boundary_type' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :user) }
      let(:field) { mock_field(directive: directive) }
      let(:type) { mock_type('QueryType', fields: { 'project' => field }) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'QueryType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(
          /\[field\] QueryType\.project: read_project.*Directive boundary_type: user/m
        ).to_stdout
      end
    end
  end
end
