# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Graphql::MountMutation do
  let_it_be(:mutation) do
    Class.new(Mutations::BaseMutation) do
      graphql_name 'TestMutation'

      argument :foo, GraphQL::Types::String, required: false
      field :bar, GraphQL::Types::String, null: true
    end
  end

  describe '.mount_mutation' do
    subject(:field) do
      mutation_type = mutation_type_factory do |f|
        f.mount_mutation(mutation)
      end

      mutation_type.get_field('testMutation')
    end

    it 'mounts a mutation' do
      expect(field.mutation).to be_present
    end
  end

  describe '.mount_aliased_mutation' do
    subject(:field) do
      mutation_type = mutation_type_factory do |f|
        f.mount_aliased_mutation('MyAlias', mutation)
      end

      mutation_type.get_field('myAlias')
    end

    it 'mounts a mutation' do
      expect(field.mutation).to be_present
    end

    it 'has a correct `graphql_name`' do
      expect(field.mutation.graphql_name).to eq('MyAlias')
    end

    it 'has a correct type' do
      expect(field.type.to_type_signature).to eq('MyAliasPayload')
    end

    it 'has a correct input argument' do
      expect(field.arguments['input'].type.unwrap.to_type_signature).to eq('MyAliasInput')
    end
  end

  def mutation_type_factory
    Class.new(::Types::BaseObject) do
      include Gitlab::Graphql::MountMutation

      graphql_name 'MutationType'

      yield(self) if block_given?
    end
  end
end
