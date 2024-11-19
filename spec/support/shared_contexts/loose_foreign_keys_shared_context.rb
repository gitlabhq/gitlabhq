# frozen_string_literal: true

RSpec.shared_context 'for loose foreign keys' do
  include LooseForeignKeysHelper

  # Generally it's reasonable to assume only one FK between tables. If there is more than one, you need
  # to specify which column you want to be testing with `lfk_column`.
  let(:lfk_column) { nil }
  let(:foreign_key_definition) do
    foreign_keys_for_parent = Gitlab::Database::LooseForeignKeys.definitions_by_table[parent.class.table_name]

    foreign_keys_for_parent.find do |definition|
      definition.from_table == model.class.table_name &&
        (lfk_column.nil? || definition.options[:column].to_sym == lfk_column.to_sym)
    end
  end

  def find_model
    query = model.class

    # handle composite primary keys
    connection = model.class.connection
    primary_keys = connection.primary_keys(model.class.table_name) - model.class.ignored_columns

    # handle overridden primary key (eg: Vulnerabilities::Read)
    model_reported_primary_key = model.class.primary_key
    if model_reported_primary_key && primary_keys.exclude?(model_reported_primary_key)
      primary_keys = Array.wrap(model_reported_primary_key)
    end

    primary_keys.each do |primary_key|
      query = query.where(primary_key => model.public_send(primary_key))
    end
    query.first
  end
end
