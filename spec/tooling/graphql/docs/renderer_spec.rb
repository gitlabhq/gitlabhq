# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../../../tooling/graphql/docs/renderer'

RSpec.describe Tooling::Graphql::Docs::Renderer do
  let(:template) { Rails.root.join('tooling/graphql/docs/templates/default.md.haml') }
  let(:field_description) { 'List of objects.' }
  let(:type) { ::GraphQL::Types::Int }

  let(:query_type) do
    Class.new(Types::BaseObject) { graphql_name 'Query' }.tap do |t|
      # this keeps type and field_description in scope.
      t.field :foo, type, null: true, description: field_description do
        argument :id, GraphQL::Types::ID, required: false, description: 'ID of the object.'
      end
    end
  end

  let(:mutation_root) do
    Class.new(::Types::BaseObject) do
      include ::Gitlab::Graphql::MountMutation
      graphql_name 'Mutation'
    end
  end

  let(:mock_schema) do
    Class.new(GraphQL::Schema) do
      def resolve_type(obj, ctx)
        raise 'Not a real schema'
      end
    end
  end

  describe '#contents' do
    shared_examples 'renders correctly as GraphQL documentation' do
      it 'contains the expected section' do
        # duplicative - but much better error messages!
        section.lines.each { |line| expect(contents).to include(line) }
        expect(contents).to include(section)
      end
    end

    subject(:contents) do
      mock_schema.query(query_type)
      mock_schema.mutation(mutation_root) if mutation_root.fields.any?

      described_class.new(
        mock_schema,
        output_dir: nil,
        template: template
      ).contents
    end

    describe 'headings' do
      it 'contains the expected sections' do
        expect(contents.lines.map(&:chomp)).to include(
          '## `Query` type',
          '## `Mutation` type',
          '## Connections',
          '## Object types',
          '## Enumeration types',
          '## Scalar types',
          '## Abstract types',
          '### Unions',
          '### Interfaces',
          '## Input types'
        )
      end
    end

    context 'when a field has a list type' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'ArrayTest'

          field :foo, [GraphQL::Types::String], null: false, description: 'A description.'
        end
      end

      specify do
        type_name = '[String!]!'
        inner_type = 'string'
        expectation = <<~DOC
          ### `ArrayTest`

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="arraytestfoo"></a>`foo` | [`#{type_name}`](##{inner_type}) | A description. |
        DOC

        is_expected.to include(expectation)
      end

      describe 'a top level query field' do
        let(:expectation) do
          <<~DOC
            ### `Query.foo`

            List of objects.

            Returns [`ArrayTest`](#arraytest).

            #### Arguments

            | Name | Type | Description |
            | ---- | ---- | ----------- |
            | <a id="queryfooid"></a>`id` | [`ID`](#id) | ID of the object. |
          DOC
        end

        it 'generates the query with arguments' do
          expect(subject).to include(expectation)
        end

        context 'when description does not end with `.`' do
          let(:field_description) { 'List of objects' }

          it 'adds the `.` to the end' do
            expect(subject).to include(expectation)
          end
        end
      end
    end

    describe 'when fields are not defined in alphabetical order' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'OrderingTest'

          field :foo, GraphQL::Types::String, null: false, description: 'A description of foo field.'
          field :bar, GraphQL::Types::String, null: false, description: 'A description of bar field.'
        end
      end

      it 'lists the fields in alphabetical order' do
        expectation = <<~DOC
          ### `OrderingTest`

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="orderingtestbar"></a>`bar` | [`String!`](#string) | A description of bar field. |
          | <a id="orderingtestfoo"></a>`foo` | [`String!`](#string) | A description of foo field. |
        DOC

        is_expected.to include(expectation)
      end
    end

    context 'when a field has a documentation reference' do
      let(:type) do
        wibble = Class.new(::Types::BaseObject) do
          graphql_name 'Wibble'
          field :x, ::GraphQL::Types::Int, null: false
        end

        Class.new(Types::BaseObject) do
          graphql_name 'DocRefSpec'
          description 'Testing doc refs'

          field :foo,
            type: GraphQL::Types::String,
            null: false,
            description: 'The foo.',
            see: { 'A list of foos' => 'https://example.com/foos' }
          field :bar,
            type: GraphQL::Types::String,
            null: false,
            description: 'The bar.',
            see: { 'A list of bars' => 'https://example.com/bars' } do
            argument :barity, ::GraphQL::Types::Int, required: false, description: '?'
          end
          field :wibbles,
            type: wibble.connection_type,
            null: true,
            description: 'The wibbles',
            see: { 'wibblance' => 'https://example.com/wibbles' }
        end
      end

      let(:section) do
        <<~DOC
          ### `DocRefSpec`

          Testing doc refs.

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="docrefspecfoo"></a>`foo` | [`String!`](#string) | The foo. See [A list of foos](https://example.com/foos). |
          | <a id="docrefspecwibbles"></a>`wibbles` | [`WibbleConnection`](#wibbleconnection) | The wibbles. See [wibblance](https://example.com/wibbles). (see [Connections](#connections)) |

          #### Fields with arguments

          ##### `DocRefSpec.bar`

          The bar. See [A list of bars](https://example.com/bars).

          Returns [`String!`](#string).

          ###### Arguments

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="docrefspecbarbarity"></a>`barity` | [`Int`](#int) | ?. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when an argument is deprecated' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'DeprecatedTest'
          description 'A thing we used to use, but no longer support'

          field :foo,
            type: GraphQL::Types::String,
            null: false,
            description: 'A description.' do
            argument :foo_arg, GraphQL::Types::String,
              required: false,
              description: 'The argument.',
              deprecated: { reason: 'Bad argument', milestone: '101.2' }
          end
        end
      end

      let(:section) do
        <<~DOC
         ##### `DeprecatedTest.foo`

         A description.

         Returns [`String!`](#string).

         ###### Arguments

         | Name | Type | Description |
         | ---- | ---- | ----------- |
         | <a id="deprecatedtestfoofooarg"></a>`fooArg` **{warning-solid}** | [`String`](#string) | **Deprecated** in GitLab 101.2. Bad argument. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a field is deprecated' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'DeprecatedTest'
          description 'A thing we used to use, but no longer support'

          field :foo,
            type: GraphQL::Types::String,
            null: false,
            deprecated: { reason: 'This is deprecated', milestone: '1.10' },
            description: 'A description.'
          field :foo_with_args,
            type: GraphQL::Types::String,
            null: false,
            deprecated: { reason: 'Do not use', milestone: '1.10', replacement: 'X.y' },
            description: 'A description.' do
            argument :arg, GraphQL::Types::Int, required: false, description: 'Argity'
          end
          field :bar,
            type: GraphQL::Types::String,
            null: false,
            description: 'A description.',
            deprecated: {
              reason: :renamed,
              milestone: '1.10',
              replacement: 'Query.boom'
            }
        end
      end

      let(:section) do
        <<~DOC
          ### `DeprecatedTest`

          A thing we used to use, but no longer support.

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="deprecatedtestbar"></a>`bar` **{warning-solid}** | [`String!`](#string) | **Deprecated** in GitLab 1.10. This was renamed. Use: [`Query.boom`](#queryboom). |
          | <a id="deprecatedtestfoo"></a>`foo` **{warning-solid}** | [`String!`](#string) | **Deprecated** in GitLab 1.10. This is deprecated. |

          #### Fields with arguments

          ##### `DeprecatedTest.fooWithArgs`

          A description.

          DETAILS:
          **Deprecated** in GitLab 1.10.
          Do not use.
          Use: [`X.y`](#xy).

          Returns [`String!`](#string).

          ###### Arguments

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="deprecatedtestfoowithargsarg"></a>`arg` | [`Int`](#int) | Argity. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a Query.field is deprecated' do
      before do
        query_type.field(
          name: :bar,
          type: type,
          null: true,
          description: 'A bar',
          deprecated: { reason: :renamed, milestone: '10.11', replacement: 'Query.foo' }
        )
      end

      let(:type) { ::GraphQL::Types::Int }
      let(:section) do
        <<~DOC
          ### `Query.bar`

          A bar.

          DETAILS:
          **Deprecated** in GitLab 10.11.
          This was renamed.
          Use: [`Query.foo`](#queryfoo).

          Returns [`Int`](#int).
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when an argument is in alpha' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'AlphaTest'
          description 'A thing with arguments in alpha'

          field :foo,
            type: GraphQL::Types::String,
            null: false,
            description: 'A description.' do
            argument :foo_arg, GraphQL::Types::String,
              required: false,
              description: 'Argument description.',
              experiment: { milestone: '101.2' }
          end
        end
      end

      let(:section) do
        <<~DOC
         ##### `AlphaTest.foo`

         A description.

         Returns [`String!`](#string).

         ###### Arguments

         | Name | Type | Description |
         | ---- | ---- | ----------- |
         | <a id="alphatestfoofooarg"></a>`fooArg` **{warning-solid}** | [`String`](#string) | **Introduced** in GitLab 101.2. **Status**: Experiment. Argument description. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a field is in alpha' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'AlphaTest'
          description 'A thing with fields in alpha'

          field :foo,
            type: GraphQL::Types::String,
            null: false,
            experiment: { milestone: '1.10' },
            description: 'A description.'
          field :foo_with_args,
            type: GraphQL::Types::String,
            null: false,
            experiment: { milestone: '1.10' },
            description: 'A description.' do
            argument :arg, GraphQL::Types::Int, required: false, description: 'Argity'
          end
        end
      end

      let(:section) do
        <<~DOC
          ### `AlphaTest`

          A thing with fields in alpha.

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="alphatestfoo"></a>`foo` **{warning-solid}** | [`String!`](#string) | **Introduced** in GitLab 1.10. **Status**: Experiment. A description. |

          #### Fields with arguments

          ##### `AlphaTest.fooWithArgs`

          A description.

          DETAILS:
          **Introduced** in GitLab 1.10.
          **Status**: Experiment.

          Returns [`String!`](#string).

          ###### Arguments

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="alphatestfoowithargsarg"></a>`arg` | [`Int`](#int) | Argity. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a Query.field is in alpha' do
      before do
        query_type.field(
          name: :bar,
          type: type,
          null: true,
          description: 'A bar',
          experiment: { milestone: '10.11' }
        )
      end

      let(:type) { ::GraphQL::Types::Int }
      let(:section) do
        <<~DOC
          ### `Query.bar`

          A bar.

          DETAILS:
          **Introduced** in GitLab 10.11.
          **Status**: Experiment.

          Returns [`Int`](#int).
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a field has an Enumeration type' do
      let(:type) do
        enum_type = Class.new(Types::BaseEnum) do
          graphql_name 'MyEnum'
          description 'A test of an enum.'

          value 'BAZ',
            description: 'A description of BAZ.'
          value 'BAR',
            description: 'A description of BAR.',
            deprecated: { reason: 'This is deprecated', milestone: '1.10' }
          value 'BOOP',
            description: 'A description of BOOP.',
            deprecated: { reason: :renamed, replacement: 'MyEnum.BAR', milestone: '1.10' }
        end

        Class.new(Types::BaseObject) do
          graphql_name 'EnumTest'

          field :foo, enum_type, null: false, description: 'A description of foo field.'
        end
      end

      let(:section) do
        <<~DOC
          ### `MyEnum`

          A test of an enum.

          | Value | Description |
          | ----- | ----------- |
          | <a id="myenumbar"></a>`BAR` **{warning-solid}** | **Deprecated** in GitLab 1.10. This is deprecated. |
          | <a id="myenumbaz"></a>`BAZ` | A description of BAZ. |
          | <a id="myenumboop"></a>`BOOP` **{warning-solid}** | **Deprecated** in GitLab 1.10. This was renamed. Use: [`MyEnum.BAR`](#myenumbar). |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when a field has a global ID type' do
      let(:type) do
        Class.new(Types::BaseObject) do
          graphql_name 'IDTest'
          description 'A test for rendering IDs.'

          field :foo, ::Types::GlobalIDType[::User], null: true, description: 'A user foo.'
        end
      end

      describe 'section for IDTest' do
        let(:section) do
          <<~DOC
            ### `IDTest`

            A test for rendering IDs.

            #### Fields

            | Name | Type | Description |
            | ---- | ---- | ----------- |
            | <a id="idtestfoo"></a>`foo` | [`UserID`](#userid) | A user foo. |
          DOC
        end

        it_behaves_like 'renders correctly as GraphQL documentation'
      end

      describe 'section for UserID' do
        let(:section) do
          <<~DOC
            ### `UserID`

            A `UserID` is a global ID. It is encoded as a string.

            An example `UserID` is: `"gid://gitlab/User/1"`.
          DOC
        end

        it_behaves_like 'renders correctly as GraphQL documentation'
      end
    end

    context 'when there is a mutation' do
      let(:mutation) do
        mutation = Class.new(::Mutations::BaseMutation)

        mutation.graphql_name 'MakeItPretty'
        mutation.description 'Make everything very pretty.'

        mutation.argument :prettiness_factor,
          type: GraphQL::Types::Float,
          required: true,
          description: 'How much prettier?'

        mutation.argument :pulchritude,
          type: GraphQL::Types::Float,
          required: false,
          description: 'How much prettier?',
          deprecated: {
            reason: :renamed,
            replacement: 'prettinessFactor',
            milestone: '72.34'
          }

        mutation.field :everything,
          type: GraphQL::Types::String,
          null: true,
          description: 'What we made prettier.'

        mutation.field :omnis,
          type: GraphQL::Types::String,
          null: true,
          description: 'What we made prettier.',
          deprecated: {
            reason: :renamed,
            replacement: 'everything',
            milestone: '72.34'
          }

        mutation
      end

      before do
        mutation_root.mount_mutation mutation
      end

      it_behaves_like 'renders correctly as GraphQL documentation' do
        let(:section) do
          <<~DOC
            ### `Mutation.makeItPretty`

            Make everything very pretty.

            Input type: `MakeItPrettyInput`

            #### Arguments

            | Name | Type | Description |
            | ---- | ---- | ----------- |
            | <a id="mutationmakeitprettyclientmutationid"></a>`clientMutationId` | [`String`](#string) | A unique identifier for the client performing the mutation. |
            | <a id="mutationmakeitprettyprettinessfactor"></a>`prettinessFactor` | [`Float!`](#float) | How much prettier?. |
            | <a id="mutationmakeitprettypulchritude"></a>`pulchritude` **{warning-solid}** | [`Float`](#float) | **Deprecated:** This was renamed. Please use `prettinessFactor`. Deprecated in GitLab 72.34. |

            #### Fields

            | Name | Type | Description |
            | ---- | ---- | ----------- |
            | <a id="mutationmakeitprettyclientmutationid"></a>`clientMutationId` | [`String`](#string) | A unique identifier for the client performing the mutation. |
            | <a id="mutationmakeitprettyerrors"></a>`errors` | [`[String!]!`](#string) | Errors encountered during execution of the mutation. |
            | <a id="mutationmakeitprettyeverything"></a>`everything` | [`String`](#string) | What we made prettier. |
            | <a id="mutationmakeitprettyomnis"></a>`omnis` **{warning-solid}** | [`String`](#string) | **Deprecated:** This was renamed. Please use `everything`. Deprecated in GitLab 72.34. |
          DOC
        end
      end

      it 'does not render the automatically generated payload type' do
        expect(contents).not_to include('MakeItPrettyPayload')
      end

      it 'does not render the automatically generated input type as its own section' do
        expect(contents).not_to include('# `MakeItPrettyInput`')
      end
    end

    context 'when there is an input type' do
      let(:type) do
        Class.new(::Types::BaseObject) do
          graphql_name 'Foo'
          field :wibble, type: ::GraphQL::Types::Int, null: true do
            argument :date_range,
              type: ::Types::TimeframeInputType,
              required: true,
              description: 'When the foo happened.'
          end
        end
      end

      let(:section) do
        <<~DOC
          ### `Timeframe`

          A time-frame defined as a closed inclusive range of two dates.

          #### Arguments

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="timeframeend"></a>`end` | [`Date!`](#date) | End of the range. |
          | <a id="timeframestart"></a>`start` | [`Date!`](#date) | Start of the range. |
        DOC
      end

      it_behaves_like 'renders correctly as GraphQL documentation'
    end

    context 'when there is an interface and a union' do
      let(:type) do
        user = Class.new(::Types::BaseObject)
        user.graphql_name 'User'
        user.field :user_field, ::GraphQL::Types::String, null: true
        group = Class.new(::Types::BaseObject)
        group.graphql_name 'Group'
        group.field :group_field, ::GraphQL::Types::String, null: true

        union = Class.new(::Types::BaseUnion)
        union.graphql_name 'UserOrGroup'
        union.description 'Either a user or a group.'
        union.possible_types user, group

        interface = Module.new
        interface.include(::Types::BaseInterface)
        interface.graphql_name 'Flying'
        interface.description 'Something that can fly.'
        interface.field :flight_speed, GraphQL::Types::Int, null: true, description: 'Speed in mph.'

        african_swallow = Class.new(::Types::BaseObject)
        african_swallow.graphql_name 'AfricanSwallow'
        african_swallow.description 'A swallow from Africa.'
        african_swallow.implements interface
        interface.orphan_types african_swallow

        Class.new(::Types::BaseObject) do
          graphql_name 'AbstractTypeTest'
          description 'A test for abstract types.'

          field :foo, union, null: true, description: 'The foo.'
          field :flying, interface, null: true, description: 'A flying thing.'
        end
      end

      it 'lists the fields correctly, and includes descriptions of all the types' do
        type_section = <<~DOC
          ### `AbstractTypeTest`

          A test for abstract types.

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="abstracttypetestflying"></a>`flying` | [`Flying`](#flying) | A flying thing. |
          | <a id="abstracttypetestfoo"></a>`foo` | [`UserOrGroup`](#userorgroup) | The foo. |
        DOC

        union_section = <<~DOC
          #### `UserOrGroup`

          Either a user or a group.

          One of:

          - [`Group`](#group)
          - [`User`](#user)
        DOC

        interface_section = <<~DOC
          #### `Flying`

          Something that can fly.

          Implementations:

          - [`AfricanSwallow`](#africanswallow)

          ##### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="flyingflightspeed"></a>`flightSpeed` | [`Int`](#int) | Speed in mph. |
        DOC

        implementation_section = <<~DOC
          ### `AfricanSwallow`

          A swallow from Africa.

          #### Fields

          | Name | Type | Description |
          | ---- | ---- | ----------- |
          | <a id="africanswallowflightspeed"></a>`flightSpeed` | [`Int`](#int) | Speed in mph. |
        DOC

        is_expected.to include(
          type_section,
          union_section,
          interface_section,
          implementation_section
        )
      end
    end
  end

  describe '#write' do
    let(:output_dir) { Dir.mktmpdir }
    let(:expected_file) { File.join(output_dir, '_index.md') }

    before do
      mock_schema.query(query_type)
      mock_schema.mutation(mutation_root) if mutation_root.fields.any?
    end

    after do
      FileUtils.remove_entry(output_dir)
    end

    it 'creates the output directory and writes contents to file' do
      renderer = described_class.new(
        mock_schema,
        output_dir: output_dir,
        template: template
      )

      expect(FileUtils).to receive(:mkdir_p).with(output_dir).and_call_original
      expect(File).to receive(:write).with(expected_file, renderer.contents).and_call_original

      renderer.write

      expect(File.exist?(expected_file)).to be true
      expect(File.read(expected_file)).to eq(renderer.contents)
    end
  end
end
