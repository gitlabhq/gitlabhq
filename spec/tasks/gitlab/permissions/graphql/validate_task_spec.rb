# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Graphql::ValidateTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }

  def mock_directive(permissions:, boundary_type:)
    Class.new(Directives::Authz::GranularScope).allocate.tap do |d|
      allow(d).to receive(:arguments).and_return(
        permissions: Array(permissions).map(&:to_s).map(&:upcase),
        boundary_type: boundary_type.to_s
      )
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

  describe '#find_mutation_directives' do
    context 'when directive is on the field' do
      it 'returns the directives from the field without checking the resolver' do
        directive = mock_directive(permissions: :read_project, boundary_type: :project)
        field = mock_field(directive: directive)
        resolver = mock_resolver(graphql_name: 'TestMutation')

        expect(task.send(:find_mutation_directives, field, resolver)).to contain_exactly(directive)
      end
    end

    context 'when field does not respond to :directives' do
      it 'checks the resolver for directives' do
        directive = mock_directive(permissions: :read_project, boundary_type: :project)
        field = Object.new
        field.define_singleton_method(:respond_to?) { |_, *| false }
        resolver = mock_resolver(graphql_name: 'TestMutation', directive: directive)

        expect(task.send(:find_mutation_directives, field, resolver)).to contain_exactly(directive)
      end
    end
  end

  describe '#validate_permission_exists' do
    before do
      allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions)
        .and_return([:read_project])
    end

    context 'when permission exists in assignable permissions' do
      it 'does not add a violation' do
        expect do
          task.send(:validate_permission_exists, { kind: 'type', name: 'Test' }, :read_project)
        end.not_to change { task.send(:violations)[:invalid_permission].length }
      end
    end

    context 'when permission does not exist in assignable permissions' do
      it 'adds a violation' do
        expect do
          task.send(:validate_permission_exists, { kind: 'type', name: 'Test' }, :not_a_real_permission)
        end.to change { task.send(:violations)[:invalid_permission].length }.by(1)
      end
    end
  end

  describe '#format_graphql_errors' do
    it 'returns empty string when there are no violations' do
      expect(task.send(:format_graphql_errors, :invalid_permission)).to eq('')
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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

  describe '#format_missing_authorization_errors' do
    it 'returns empty string when there are no violations' do
      expect(task.send(:format_missing_authorization_errors)).to eq('')
    end
  end

  describe '#load_todo_entries' do
    context 'when the todo file does not exist' do
      before do
        allow(described_class::TODO_FILE).to receive(:exist?).and_return(false)
      end

      it 'returns an empty set' do
        expect(task.load_todo_entries).to eq(Set.new)
      end
    end

    context 'when the todo file exists' do
      before do
        allow(described_class::TODO_FILE).to receive_messages(exist?: true,
          readlines: ["# a comment\n", "\n", "mutation:SomeMutation\n", "mutation:AnotherMutation\n"])
      end

      it 'returns a set of non-comment, non-blank entries' do
        expect(task.load_todo_entries).to eq(Set['mutation:SomeMutation', 'mutation:AnotherMutation'])
      end
    end
  end

  describe '#current_todo_entries' do
    context 'when a mutation has no GranularScope directive' do
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

      it 'includes the mutation entry' do
        expect(task.send(:current_todo_entries)).to include('mutation:NoDirectiveMutation')
      end
    end

    context 'when a mutation has a GranularScope directive' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:resolver) { mock_resolver(graphql_name: 'DirectiveMutation', directive: directive) }
      let(:mutation_field) { mock_mutation_field(resolver: resolver) }
      let(:mutation_type) do
        fields = { 'directiveMutation' => mutation_field }
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

      it 'does not include the mutation entry' do
        expect(task.send(:current_todo_entries)).not_to include('mutation:DirectiveMutation')
      end
    end

    context 'when a type has no GranularScope directive' do
      let(:type) do
        mock_type('AuthorizedType')
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'AuthorizedType' => type,
'Mutation' => empty_mutation_type })
      end

      it 'includes the type entry' do
        expect(task.send(:current_todo_entries)).to include('type:AuthorizedType')
      end
    end

    context 'when a type has a GranularScope directive' do
      let(:directive) { mock_directive(permissions: :read_something, boundary_type: :project) }
      let(:type) do
        mock_type('AuthorizedType', directive: directive)
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'AuthorizedType' => type,
'Mutation' => empty_mutation_type })
      end

      it 'does not include the type entry' do
        expect(task.send(:current_todo_entries)).not_to include('type:AuthorizedType')
      end
    end
  end

  describe '#sync_todo' do
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
      allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions).and_return([])
      allow(task).to receive(:class_source_path).and_return('app/graphql/mutations/no_directive_mutation.rb')
    end

    context 'when the todo file is up to date' do
      before do
        allow(described_class::TODO_FILE).to receive_messages(
          exist?: true,
          readlines: ["mutation:NoDirectiveMutation\n"]
        )
      end

      it 'returns without output' do
        expect { task.sync_todo }.not_to output.to_stdout
      end
    end

    context 'when the todo file has a stale entry' do
      before do
        allow(described_class::TODO_FILE).to receive_messages(
          exist?: true,
          readlines: ["mutation:OldMutation\n"]
        )
        allow(described_class::TODO_FILE).to receive(:write)
      end

      it 'auto-updates the file and aborts with a commit reminder' do
        expect { task.sync_todo }
          .to raise_error(SystemExit)
          .and output(/had stale entries and has been updated.*Please commit/m).to_stdout
      end
    end
  end

  describe '#update_todo' do
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
      allow(described_class::TODO_FILE).to receive_messages(
        exist?: true,
        readlines: ["# GraphQL header\n"],
        write: nil
      )
    end

    it 'writes the header and sorted entries to the todo file and outputs an updated message' do
      expect { task.update_todo }.to output(/updated/).to_stdout
      expect(described_class::TODO_FILE).to have_received(:write)
        .with("# GraphQL header\nmutation:NoDirectiveMutation\n")
    end
  end

  describe '#run', :unlimited_max_formatted_output_length do
    subject(:run) { task.run }

    before do
      allow(GitlabSchema).to receive(:types).and_return({ 'Mutation' => empty_mutation_type })
      allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions)
        .and_return([:read_project, :update_project, :create_issue, :read_something])
      allow(task).to receive(:class_source_path).and_return('app/graphql/types/test_type.rb')
      allow(described_class::TODO_FILE).to receive_messages(exist?: true, readlines: [])
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has mixed directive types' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:other_directive) do
        Object.new.tap do |mocked_directive|
          allow(mocked_directive).to receive(:is_a?).and_return(false)
        end
      end

      let(:type) do
        mock_type('ProjectType').tap do |mocked_type|
          allow(mocked_type).to receive(:directives).and_return([other_directive, directive])
        end
      end

      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'ProjectType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'skips non-GranularScope type directives and validates the granular one' do
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error with boundary details' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL types/mutations/fields have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the directive's boundary_type, or fix the directive's boundary_type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#determining-boundaries
          #
          #    - [type] SomethingType: read_something (app/graphql/types/test_type.rb)
          #        Directive boundary_type: user
          #        Assignable boundaries: project, group
          #
          #######################################################################
        OUTPUT
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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
        allow(described_class::TODO_FILE).to receive_messages(exist?: true, readlines: [])
      end

      it 'reports a missing_authorization violation' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL mutations and/or types are missing granular token authorization.
          #  Add `authorize_granular_token` with permissions and boundary_type to the mutation or type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/graphql_implementation_guide
          #
          #    - [mutation] NoDirectiveMutation (app/graphql/types/test_type.rb)
          #
          #######################################################################
        OUTPUT
      end

      context 'when the mutation is listed in the todo file' do
        before do
          allow(task).to receive(:load_todo_entries).and_return(Set['mutation:NoDirectiveMutation'])
        end

        it 'completes successfully' do
          expect { run }.to output(/GraphQL permissions are valid/).to_stdout
        end
      end
    end

    context 'when a type has no GranularScope directive' do
      let(:type) do
        mock_type('CustomEmojiType')
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'CustomEmojiType' => type, 'Mutation' => empty_mutation_type
        )
        allow(described_class::TODO_FILE).to receive_messages(exist?: true, readlines: [])
      end

      it 'reports a missing_authorization violation' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL mutations and/or types are missing granular token authorization.
          #  Add `authorize_granular_token` with permissions and boundary_type to the mutation or type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/graphql_implementation_guide
          #
          #    - [type] CustomEmojiType (app/graphql/types/test_type.rb)
          #
          #######################################################################
        OUTPUT
      end

      context 'when the type is listed in the todo file' do
        before do
          allow(task).to receive(:load_todo_entries).and_return(Set['type:CustomEmojiType'])
        end

        it 'completes successfully' do
          expect { run }.to output(/GraphQL permissions are valid/).to_stdout
        end
      end
    end

    context 'when a type has a GranularScope directive' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:type) do
        mock_type('CustomEmojiType', directive: directive)
      end

      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'CustomEmojiType' => type, 'Mutation' => empty_mutation_type
        )
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:create_issue).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL types/mutations/fields have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the directive's boundary_type, or fix the directive's boundary_type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#determining-boundaries
          #
          #    - [mutation] CreateIssue: create_issue (app/graphql/types/test_type.rb)
          #        Directive boundary_type: instance
          #        Assignable boundaries: project, group
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a field has a directive with valid boundary_type' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:field) { mock_field(directive: directive) }
      let(:type) { mock_type('QueryType', fields: { 'project' => field }) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["type:QueryType\n"])
        allow(GitlabSchema).to receive(:types).and_return({ 'QueryType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["type:QueryType\n"])
        allow(GitlabSchema).to receive(:types).and_return(
          'QueryType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'skips the field and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a field has mixed directive types' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:other_directive) do
        Object.new.tap do |mocked_directive|
          allow(mocked_directive).to receive(:is_a?).and_return(false)
        end
      end

      let(:field) do
        mock_field.tap do |mocked_field|
          allow(mocked_field).to receive(:directives).and_return([other_directive, directive])
        end
      end

      let(:type) { mock_type('QueryType', fields: { 'project' => field }) }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["type:QueryType\n"])
        allow(GitlabSchema).to receive(:types).and_return({ 'QueryType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'skips non-GranularScope field directives and validates the granular one' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type directive has nil boundary_type' do
      let(:directive) do
        Class.new(Directives::Authz::GranularScope).allocate.tap do |d|
          allow(d).to receive(:arguments).and_return(
            permissions: ['READ_PROJECT'],
            boundary_type: nil
          )
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
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["type:SomeType\n"])
        allow(GitlabSchema).to receive(:types).and_return(
          'SomeType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'skips the field and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type uses a deprecated permission' do
      let(:directive) { mock_directive(permissions: :deprecated_action, boundary_type: :project) }
      let(:type) { mock_type('DeprecatedType', directive: directive) }

      before do
        allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions)
          .and_return([:read_project, :update_project])
        allow(GitlabSchema).to receive(:types).and_return(
          'DeprecatedType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'returns an error listing the deprecated permission as invalid' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL types/mutations/fields reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - [type] DeprecatedType: deprecated_action (app/graphql/types/test_type.rb)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a type has a deprecated permission with mismatched boundary' do
      let(:directive) { mock_directive(permissions: :deprecated_action, boundary_type: :user) }
      let(:type) { mock_type('DeprecatedType', directive: directive) }
      let(:deprecated_assignable) do
        instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project], deprecated?: true)
      end

      before do
        allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions)
          .and_return([:read_project, :update_project, :deprecated_action])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:deprecated_action).and_return([])
        allow(GitlabSchema).to receive(:types).and_return(
          'DeprecatedType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'skips boundary validation when no available assignables exist' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end

    context 'when a type has an invalid permission' do
      let(:directive) { mock_directive(permissions: :not_a_real_permission, boundary_type: :project) }
      let(:type) { mock_type('BadType', directive: directive) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'BadType' => type, 'Mutation' => empty_mutation_type
        )
      end

      it 'returns an error listing the invalid permission' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL types/mutations/fields reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - [type] BadType: not_a_real_permission (app/graphql/types/test_type.rb)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a type has valid boundary_type but permission has no assignable groups' do
      let(:directive) { mock_directive(permissions: :read_project, boundary_type: :project) }
      let(:type) { mock_type('ProjectType', directive: directive) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'ProjectType' => type, 'Mutation' => empty_mutation_type
        )
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
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
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["type:QueryType\n"])
        allow(GitlabSchema).to receive(:types).and_return({ 'QueryType' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following GraphQL types/mutations/fields have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the directive's boundary_type, or fix the directive's boundary_type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#determining-boundaries
          #
          #    - [field] QueryType.project: read_project (app/graphql/types/test_type.rb)
          #        Directive boundary_type: user
          #        Assignable boundaries: project, group
          #
          #######################################################################
        OUTPUT
      end
    end

    describe 'multi-boundary directive support' do
      let(:type) do
        directives = %i[project group instance].map do |bt|
          mock_directive(permissions: :read_runner, boundary_type: bt)
        end
        assignable = instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[group instance project])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_runner).and_return([assignable])

        type = Object.new
        type.define_singleton_method(:name) { 'CiRunner' }
        type.define_singleton_method(:kind) { type }
        type.define_singleton_method(:object?) { true }
        type.define_singleton_method(:directives) { directives }
        type.define_singleton_method(:respond_to?) { |method, *| %i[kind directives].include?(method) }
        type
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return({ 'CiRunner' => type, 'Mutation' => empty_mutation_type })
        allow(Authz::PermissionGroups::Assignable).to receive(:available_permissions)
          .and_return([:read_project, :read_runner])
      end

      it 'validates all directives and completes successfully' do
        expect { run }.to output(/GraphQL permissions are valid/).to_stdout
      end
    end
  end
end
