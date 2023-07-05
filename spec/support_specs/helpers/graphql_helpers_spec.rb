# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlHelpers do
  include described_class

  # Normalize irrelevant whitespace to make comparison easier
  def norm(query)
    query.tr("\n", ' ').gsub(/\s+/, ' ').strip
  end

  describe 'a_graphql_entity_for' do
    context 'when no arguments are passed' do
      it 'raises an error' do
        expect { a_graphql_entity_for }.to raise_error(ArgumentError)
      end
    end

    context 'when the model is nil, with no properties' do
      it 'raises an error' do
        expect { a_graphql_entity_for(nil) }.to raise_error(ArgumentError)
      end
    end

    context 'when the model is nil, any fields are passed' do
      it 'raises an error' do
        expect { a_graphql_entity_for(nil, :username) }.to raise_error(ArgumentError)
      end
    end

    context 'with no model' do
      it 'behaves like hash-inclusion with camel-casing' do
        response = { 'foo' => 1, 'bar' => 2, 'camelCased' => 3 }

        expect(response).to match a_graphql_entity_for(foo: 1, camel_cased: 3)
        expect(response).not_to match a_graphql_entity_for(missing: 5)
      end
    end

    context 'with just a model' do
      it 'only considers the ID' do
        user = build_stubbed(:user)
        response = { 'username' => 'foo', 'id' => global_id_of(user).to_s }

        expect(response).to match a_graphql_entity_for(user)
      end
    end

    context 'with a model and some method names' do
      it 'also considers the method names' do
        user = build_stubbed(:user)
        response = { 'username' => user.username, 'id' => global_id_of(user).to_s }

        expect(response).to match a_graphql_entity_for(user, :username)
        expect(response).not_to match a_graphql_entity_for(user, :name)
      end
    end

    context 'with a model and some other properties' do
      it 'behaves like the superset' do
        user = build_stubbed(:user)
        response = { 'username' => 'foo', 'id' => global_id_of(user).to_s }

        expect(response).to match a_graphql_entity_for(user, username: 'foo')
        expect(response).not_to match a_graphql_entity_for(user, name: 'foo')
      end
    end

    context 'with a model, method names, and some other properties' do
      it 'behaves like the superset' do
        user = build_stubbed(:user)
        response = {
          'username' => user.username,
          'name' => user.name,
          'foo' => 'bar',
          'baz' => 'fop',
          'id' => global_id_of(user).to_s
        }

        expect(response).to match a_graphql_entity_for(user, :username, :name, foo: 'bar')
        expect(response).to match a_graphql_entity_for(user, :name, foo: 'bar')
        expect(response).not_to match a_graphql_entity_for(user, :name, bar: 'foo')
      end
    end
  end

  describe 'graphql_dig_at' do
    it 'transforms symbol keys to graphql field names' do
      data = { 'camelCased' => 'names' }

      expect(graphql_dig_at(data, :camel_cased)).to eq('names')
    end

    it 'supports integer indexing' do
      data = { 'array' => [:boom, { 'id' => :hooray! }, :boom] }

      expect(graphql_dig_at(data, :array, 1, :id)).to eq(:hooray!)
    end

    it 'gracefully degrades to nil' do
      data = { 'project' => { 'mergeRequest' => nil } }

      expect(graphql_dig_at(data, :project, :merge_request, :id)).to be_nil
    end

    it 'supports implicitly flat-mapping traversals' do
      data = {
        'foo' => {
          'nodes' => [
            { 'bar' => { 'nodes' => [{ 'id' => 1 }, { 'id' => 2 }] } },
            { 'bar' => { 'nodes' => [{ 'id' => 3 }, { 'id' => 4 }] } },
            { 'bar' => nil }
          ]
        },
        'irrelevant' => 'the field is a red-herring'
      }

      expect(graphql_dig_at(data, :foo, :nodes, :bar, :nodes, :id)).to eq([1, 2, 3, 4])
    end

    it 'does not omit nils at the leaves' do
      data = {
        'foo' => {
          'nodes' => [
            { 'bar' => { 'nodes' => [{ 'id' => nil }, { 'id' => 2 }] } },
            { 'bar' => { 'nodes' => [{ 'id' => 3 }, { 'id' => nil }] } },
            { 'bar' => nil }
          ]
        },
        'irrelevant' => 'the field is a red-herring'
      }

      expect(graphql_dig_at(data, :foo, :nodes, :bar, :nodes, :id)).to eq([nil, 2, 3, nil])
    end

    it 'supports fields with leading underscore' do
      web_path = '/namespace1/project1/-/packages/997'
      data = {
        'packages' => {
          'nodes' => [
            {
              '_links' => {
                'webPath' => web_path
              }
            }
          ]
        }
      }

      expect(graphql_dig_at(data, :packages, :nodes, :_links, :web_path)).to match_array([web_path])
    end
  end

  describe 'var' do
    it 'allocates a fresh name for each var' do
      a = var('Int')
      b = var('Int')

      expect(a.name).not_to eq(b.name)
    end

    it 'can be used to construct correct signatures' do
      a = var('Int')
      b = var('String!')

      q = with_signature([a, b], '{ foo bar }')

      expect(q).to eq("query(#{a.to_graphql_value}: Int, #{b.to_graphql_value}: String!) { foo bar }")
    end

    it 'can be used to pass arguments to fields' do
      a = var('ID!')

      q = graphql_query_for(:project, { full_path: a }, :id)

      expect(norm(q)).to eq("{ project(fullPath: #{a.to_graphql_value}){ id } }")
    end

    it 'can associate values with variables' do
      a = var('Int')

      expect(a.with(3).to_h).to eq(a.name => 3)
    end

    it 'does not mutate the variable when providing a value' do
      a = var('Int')
      three = a.with(3)

      expect(three.value).to eq(3)
      expect(a.value).to be_nil
    end

    it 'can associate many values with variables' do
      a = var('Int').with(3)
      b = var('String').with('foo')

      expect(serialize_variables([a, b])).to eq({ a.name => 3, b.name => 'foo' }.to_json)
    end
  end

  describe '.query_nodes' do
    it 'can produce a basic connection selection' do
      selection = query_nodes(:users)

      expected = query_graphql_path([:users, :nodes], all_graphql_fields_for('User', max_depth: 1))

      expect(selection).to eq(expected)
    end

    it 'allows greater depth' do
      selection = query_nodes(:users, max_depth: 2)

      expected = query_graphql_path([:users, :nodes], all_graphql_fields_for('User', max_depth: 2))

      expect(selection).to eq(expected)
    end

    it 'accepts fields' do
      selection = query_nodes(:users, :id)

      expected = query_graphql_path([:users, :nodes], :id)

      expect(selection).to eq(expected)
    end

    it 'accepts arguments' do
      args = { username: 'foo' }
      selection = query_nodes(:users, args: args)

      expected = query_graphql_path([[:users, args], :nodes], all_graphql_fields_for('User', max_depth: 1))

      expect(selection).to eq(expected)
    end

    it 'accepts arguments and fields' do
      selection = query_nodes(:users, :id, args: { username: 'foo' })

      expected = query_graphql_path([[:users, { username: 'foo' }], :nodes], :id)

      expect(selection).to eq(expected)
    end

    it 'accepts explicit type name' do
      selection = query_nodes(:members, of: 'User')

      expected = query_graphql_path([:members, :nodes], all_graphql_fields_for('User', max_depth: 1))

      expect(selection).to eq(expected)
    end

    it 'can optionally provide pagination info' do
      selection = query_nodes(:users, include_pagination_info: true)

      expected = query_graphql_path([:users, "#{page_info_selection} nodes"], all_graphql_fields_for('User', max_depth: 1))

      expect(selection).to eq(expected)
    end
  end

  describe '.query_graphql_path' do
    it 'can build nested paths' do
      selection = query_graphql_path(%i[foo bar wibble_wobble], :id)

      expected = norm(<<-GQL)
      foo{
        bar{
          wibbleWobble{
            id
          }
        }
      }
      GQL

      expect(norm(selection)).to eq(expected)
    end

    it 'can insert arguments at any point' do
      selection = query_graphql_path(
        [:foo, [:bar, { quux: true }], [:wibble_wobble, { eccentricity: :HIGH }]],
        :id
      )

      expected = norm(<<-GQL)
      foo{
        bar(quux: true){
          wibbleWobble(eccentricity: HIGH){
            id
          }
        }
      }
      GQL

      expect(norm(selection)).to eq(expected)
    end
  end

  describe '.attributes_to_graphql' do
    it 'can serialize hashes to literal arguments' do
      x = var('Int')
      args = {
        an_array: [1, nil, "foo", true, [:foo, :bar]],
        a_hash: {
          nested: true,
          value: "bar"
        },
        an_int: 42,
        a_float: 0.1,
        a_string: "wibble",
        an_enum: :LOW,
        null: nil,
        a_bool: false,
        a_var: x
      }

      literal = attributes_to_graphql(args)

      expect(norm(literal)).to eq(norm(<<~EXP))
      anArray: [1,null,"foo",true,[foo,bar]],
      aHash: {nested: true, value: "bar"},
      anInt: 42,
      aFloat: 0.1,
      aString: "wibble",
      anEnum: LOW,
      null: null,
      aBool: false,
      aVar: #{x.to_graphql_value}
      EXP
    end
  end

  describe '.all_graphql_fields_for' do
    it 'returns a FieldSelection' do
      selection = all_graphql_fields_for('User', max_depth: 1)

      expect(selection).to be_a(::Graphql::FieldSelection)
    end

    it 'returns nil if the depth is too shallow' do
      selection = all_graphql_fields_for('User', max_depth: 0)

      expect(selection).to be_nil
    end

    it 'can select just the scalar fields' do
      selection = all_graphql_fields_for('User', max_depth: 1)
      paths = selection.paths.map(&:join)

      # A sample, tested using include to save churn as fields are added
      expect(paths)
        .to include(*%w[avatarUrl email groupCount id location name state username webPath webUrl])

      expect(selection.paths).to all(have_attributes(size: 1))
    end

    it 'selects only as far as 3 levels by default' do
      selection = all_graphql_fields_for('User')

      expect(selection.paths).to all(have_attributes(size: (be <= 3)))

      # Representative sample
      expect(selection.paths).to include(
        %w[userPermissions createSnippet],
        %w[todos nodes id],
        %w[starredProjects nodes name],
        %w[authoredMergeRequests count],
        %w[assignedMergeRequests pageInfo startCursor]
      )
    end

    it 'selects only as far as requested' do
      selection = all_graphql_fields_for('User', max_depth: 2)

      expect(selection.paths).to all(have_attributes(size: (be <= 2)))
    end

    it 'omits fields that have required arguments' do
      selection = all_graphql_fields_for('DesignCollection', max_depth: 3)

      expect(selection.paths).not_to be_empty

      expect(selection.paths).not_to include(
        %w[designAtVersion id]
      )
    end
  end

  describe '.graphql_mutation' do
    shared_examples 'correct mutation definition' do
      it 'returns correct mutation definition' do
        query = <<~MUTATION
          mutation($updateAlertStatusInput: UpdateAlertStatusInput!) {
            updateAlertStatus(input: $updateAlertStatusInput) {
              clientMutationId
            }
          }
        MUTATION
        variables = { "updateAlertStatusInput" => { "projectPath" => "test/project" } }

        is_expected.to eq(GraphqlHelpers::MutationDefinition.new(query, variables))
      end
    end

    context 'when fields argument is passed' do
      subject do
        graphql_mutation(:update_alert_status, { project_path: 'test/project' }, 'clientMutationId')
      end

      it_behaves_like 'correct mutation definition'
    end

    context 'when block is passed' do
      subject do
        graphql_mutation(:update_alert_status, { project_path: 'test/project' }) do
          'clientMutationId'
        end
      end

      it_behaves_like 'correct mutation definition'
    end

    context 'when both fields and a block are passed' do
      subject do
        graphql_mutation(:mutation_name, { variable_name: 'variable/value' }, 'fieldName') do
          'fieldName'
        end
      end

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(
          ArgumentError,
          'Please pass either `fields` parameter or a block to `#graphql_mutation`, but not both.'
        )
      end
    end
  end

  describe '.fieldnamerize' do
    subject { described_class.fieldnamerize(field) }

    let(:field) { 'merge_request' }

    it 'makes an underscored string look like a fieldname' do
      is_expected.to eq('mergeRequest')
    end

    context 'when field has a leading underscore' do
      let(:field) { :_links }

      it 'skips a transformation' do
        is_expected.to eq('_links')
      end
    end
  end
end
