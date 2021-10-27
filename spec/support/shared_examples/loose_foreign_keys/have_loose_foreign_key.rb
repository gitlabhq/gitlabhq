# frozen_string_literal: true

RSpec.shared_examples 'it has loose foreign keys' do
  let(:factory_name) { nil }
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }

  it 'includes the LooseForeignKey module' do
    expect(described_class.ancestors).to include(LooseForeignKey)
  end

  it 'responds to #loose_foreign_key_definitions' do
    expect(described_class).to respond_to(:loose_foreign_key_definitions)
  end

  it 'has at least one loose foreign key definition' do
    expect(described_class.loose_foreign_key_definitions.size).to be > 0
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
    model.destroy!

    deleted_record = LooseForeignKeys::DeletedRecord.find_by(fully_qualified_table_name: "#{connection.current_schema}.#{table_name}", primary_key_value: model.id)

    expect(deleted_record).not_to be_nil
  end

  it 'cleans up record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang

    expect { model.destroy! }.to change { LooseForeignKeys::DeletedRecord.count }.by(1)

    LooseForeignKeys::ProcessDeletedRecordsService.new(connection: connection).execute

    expect(LooseForeignKeys::DeletedRecord.status_pending.count).to be(0)
    expect(LooseForeignKeys::DeletedRecord.status_processed.count).to be(1)
  end
end
