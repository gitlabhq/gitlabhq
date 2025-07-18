# frozen_string_literal: true

RSpec.shared_examples 'it has loose foreign keys' do
  let(:factory_name) { nil }
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }
  let(:fully_qualified_table_name) { "#{connection.current_schema}.#{table_name}" }
  let(:deleted_records) { LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: fully_qualified_table_name) }

  around do |example|
    LooseForeignKeys::DeletedRecord.using_connection(connection) do
      example.run
    end
  end

  before do
    allow(Gitlab::Database::SharedModel).to receive(:using_connection).and_yield
  end

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

    deleted_record = deleted_records.find_by(primary_key_value: model.id)

    expect(deleted_record).not_to be_nil
  end

  it 'cleans up record deletions' do
    model = create(factory_name) # rubocop: disable Rails/SaveBang
    model_id = model.id

    puts "## LFK Debug: Starting test for #{table_name} with model_id: #{model_id} ##"

    # Check initial state
    initial_pending_count = deleted_records.status_pending.count
    initial_processed_count = deleted_records.status_processed.count
    initial_total_count = deleted_records.count

    puts "## LFK Debug: Initial state - Pending: #{initial_pending_count}, Processed: #{initial_processed_count}, Total: #{initial_total_count} ##"

    # Check for existing records for this model_id (shouldn't exist)
    existing_records = deleted_records.where(primary_key_value: model_id)
    puts "## LFK Debug: Existing records for model_id #{model_id}: #{existing_records.count} ##"

    expect { model.delete }.to change { deleted_records.count }.by(1)

    # Check state after deletion
    after_delete_pending = deleted_records.where(primary_key_value: model_id).status_pending.count
    after_delete_processed = deleted_records.where(primary_key_value: model_id).status_processed.count
    total_pending_after_delete = deleted_records.status_pending.count
    total_processed_after_delete = deleted_records.status_processed.count

    puts "## LFK Debug: After delete - Model #{model_id} Pending: #{after_delete_pending}, Processed: #{after_delete_processed} ##"
    puts "## LFK Debug: After delete - Total Pending: #{total_pending_after_delete}, Total Processed: #{total_processed_after_delete} ##"

    # Check all pending records across all tables before processing
    all_pending_records = []
    Gitlab::Database::LooseForeignKeys.definitions_by_table.each_key do |table|
      fqtn = "#{connection.current_schema}.#{table}"
      table_records = LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: fqtn).status_pending
      all_pending_records.concat(table_records.to_a)
    end

    puts "## LFK Debug: Total pending records across all tables before processing: #{all_pending_records.count} ##"
    puts "## LFK Debug: Tables with pending records: #{all_pending_records.group_by(&:fully_qualified_table_name).transform_values(&:count)} ##"

    # Process records and capture stats
    start_time = Time.current
    service = LooseForeignKeys::ProcessDeletedRecordsService.new(connection: connection)
    stats = service.execute
    processing_time = Time.current - start_time

    puts "## LFK Debug: Processing took #{processing_time} seconds ##"
    puts "## LFK Debug: Processing stats: #{stats.inspect} ##"

    # Check state after processing
    after_process_pending = deleted_records.where(primary_key_value: model_id).status_pending.count
    after_process_processed = deleted_records.where(primary_key_value: model_id).status_processed.count
    total_pending_after_process = deleted_records.status_pending.count
    total_processed_after_process = deleted_records.status_processed.count

    puts "## LFK Debug: After processing - Model #{model_id} Pending: #{after_process_pending}, Processed: #{after_process_processed} ##"
    puts "## LFK Debug: After processing - Total Pending: #{total_pending_after_process}, Total Processed: #{total_processed_after_process} ##"

    # If the test is about to fail, provide additional debugging
    if after_process_pending != 0 || after_process_processed != 1
      puts "## LFK Debug: TEST FAILURE IMMINENT - Additional debugging ##"

      # Check if our specific record exists and its status
      our_record = deleted_records.find_by(primary_key_value: model_id)

      if our_record
        puts "## LFK Debug: Our record exists - Status: #{our_record.status}, Cleanup attempts: #{our_record.cleanup_attempts}, Consume after: #{our_record.consume_after} ##"
        puts "## LFK Debug: Our record details: #{our_record.inspect} ##"
      else
        puts "## LFK Debug: Our record not found in deleted_records table ##"
      end

      # Check if there are still pending records for our table
      table_pending = deleted_records.status_pending
      puts "## LFK Debug: Remaining pending records for #{table_name}: #{table_pending.count} ##"
      puts "## LFK Debug: Pending record IDs: #{table_pending.pluck(:primary_key_value)} ##" if table_pending.any?
    end

    expect(deleted_records.where(primary_key_value: model_id).status_pending.count).to eq(0)
    expect(deleted_records.where(primary_key_value: model_id).status_processed.count).to eq(1)
  end
end

RSpec.shared_examples 'cleanup by a loose foreign key' do |on_delete: nil|
  include_context 'for loose foreign keys'

  it 'cleans up (delete or nullify) the model' do
    expect(foreign_key_definition.on_delete).to eq(on_delete.to_sym) if on_delete.present?

    puts("##+ Additional Debug Logs for LFK flakiness +##")
    puts("## Parent: #{parent.inspect} ##")
    parent.delete
    puts("## Parent deleted ##")

    expect(find_model).to be_present

    begin
      if find_model
        puts("## Find Model: #{find_model.inspect} ##")
      else
        puts("## Find Model not present ##")
      end
    rescue NoMethodError
      puts("## Inspect causes an NoMethodError for this class. Find Model: #{find_model.class} #{find_model.id} ##")
    end

    debug_print_outstanding_lfk_records

    start_process_loose_foreign_key_deletions = Time.now
    process_loose_foreign_key_deletions(record: parent)
    puts("## LFK's processed for parent in #{Time.now - start_process_loose_foreign_key_deletions} seconds##")

    debug_print_outstanding_lfk_records

    if foreign_key_definition.on_delete.eql?(:async_delete)
      expect(find_model).not_to be_present
    else
      expect(find_model[foreign_key_definition.column]).to eq(nil)
    end

    puts("##- Additional Debug Logs for LFK flakiness end -##")
  end

  # + Debug code to be removed.
  def debug_print_outstanding_lfk_records
    Gitlab::Database::SharedModel.using_connection(parent.connection) do
      lfk_deleted_records = []
      Gitlab::Database::LooseForeignKeys.definitions_by_table.each_key do |table|
        fully_qualified_table_name = "#{parent.connection.current_schema}.#{table}"
        lfk_deleted_records << LooseForeignKeys::DeletedRecord.load_batch_for_table(fully_qualified_table_name, 1000)
      end
      lfk_deleted_records.flatten!
      puts("## #{lfk_deleted_records.count} LFK Deleted records found for parent ##")
      puts("## #{lfk_deleted_records.inspect} ##")
    end
  end
  # - Debug code to be removed.

  # rubocop:disable Cop/AvoidReturnFromBlocks -- Intentional Short Circuit
  def any_outstanding_lfk_records?(parent)
    Gitlab::Database::SharedModel.using_connection(parent.connection) do
      Gitlab::Database::LooseForeignKeys.definitions_by_table.each_key do |table|
        fully_qualified_table_name = "#{parent.connection.current_schema}.#{table}"
        return true if LooseForeignKeys::DeletedRecord.load_batch_for_table(fully_qualified_table_name, 1000).any?
      end
    end

    false
  end
  # rubocop:enable Cop/AvoidReturnFromBlocks
end

RSpec.shared_examples 'update by a loose foreign key' do
  let(:options) { foreign_key_definition.options }

  include_context 'for loose foreign keys'

  it 'updates the model' do
    unless foreign_key_definition.on_delete.eql?(:update_column_to)
      raise ArgumentError, 'Loose foreign key definition should have `update_column_to` on_delete option'
    end

    parent.delete

    process_loose_foreign_key_deletions(record: parent)

    expect(find_model.read_attribute_before_type_cast(options[:target_column])).to eq(options[:target_value])
  end
end

RSpec.shared_examples 'loose foreign key with custom delete limit' do
  let(:table_name) { described_class.table_name }

  include_context 'for loose foreign keys'

  it 'has loose foreign key definition with custom delete limit' do
    definitions = Gitlab::Database::LooseForeignKeys.definitions_by_table[table_name]
    definition = definitions.find do |definition|
      definition.from_table == from_table && definition.to_table == table_name
    end

    expect(definition.options[:delete_limit]).to eq(delete_limit)
  end
end
