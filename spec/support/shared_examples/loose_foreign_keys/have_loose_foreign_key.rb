# frozen_string_literal: true

RSpec.shared_examples 'it has loose foreign keys' do
  let(:factory_name) { nil }
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }

  it 'has at least one loose foreign key definition' do
    definitions = Gitlab::Database::LooseForeignKeys.definitions_by_table[table_name]
    expect(definitions.size).to be > 0
  end

  it 'has the deletion trigger present' do
    sql = <<-SQL
    SELECT trigger_name
    FROM information_schema.triggers
    WHERE event_object_table = '#{table_name}'
    SQL

    triggers = connection.execute(sql)

    expected_trigger_name = "#{table_name}_loose_fk_trigger"
    expect(triggers.pluck('trigger_name')).to include(expected_trigger_name)
  end

  it 'records record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang

    # using delete to avoid cross-database modification errors when associations with dependent option are present
    model.delete

    deleted_record = LooseForeignKeys::DeletedRecord.find_by(fully_qualified_table_name: "#{connection.current_schema}.#{table_name}", primary_key_value: model.id)

    expect(deleted_record).not_to be_nil
  end

  it 'cleans up record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang

    expect { model.delete }.to change { LooseForeignKeys::DeletedRecord.count }.by(1)

    LooseForeignKeys::ProcessDeletedRecordsService.new(connection: connection).execute

    expect(LooseForeignKeys::DeletedRecord.status_pending.count).to be(0)
    expect(LooseForeignKeys::DeletedRecord.status_processed.count).to be(1)
  end
end
