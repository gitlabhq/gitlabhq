# frozen_string_literal: true

RSpec.shared_context 'for loose foreign keys' do
  include LooseForeignKeysHelper

  let(:foreign_key_definition) do
    foreign_keys_for_parent = Gitlab::Database::LooseForeignKeys.definitions_by_table[parent.class.table_name]
    foreign_keys_for_parent.find { |definition| definition.from_table == model.class.table_name }
  end

  def find_model
    query = model.class
    # handle composite primary keys
    primary_keys = model.class.connection.primary_keys(model.class.table_name) - model.class.ignored_columns
    primary_keys.each do |primary_key|
      query = query.where(primary_key => model.public_send(primary_key))
    end
    query.first
  end
end
