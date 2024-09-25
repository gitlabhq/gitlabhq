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
    connection = model.class.connection
    primary_keys = connection.primary_keys(model.class.table_name) - model.class.ignored_columns

    # handle overridden primary key (eg: Vulnerabilities::Read)
    model_reported_primary_key = model.class.primary_key
    if model_reported_primary_key && primary_keys.exclude?(model_reported_primary_key)
      return query.where(model_reported_primary_key => model.public_send(model_reported_primary_key)).first
    end

    primary_keys.each do |primary_key|
      query = query.where(primary_key => model.public_send(primary_key))
    end
    query.first
  end
end
