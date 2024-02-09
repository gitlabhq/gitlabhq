# frozen_string_literal: true

module Database
  module InjectFailureHelpers
    # These methods are used by specs that inject faults into the migration procedure and then ensure
    # that it migrates correctly when rerun
    def fail_first_time
      # We can't directly use a boolean here, as we need something that will be passed by-reference to the proc
      fault_status = { faulted: false }
      proc do |m, *args, **kwargs|
        next m.call(*args, **kwargs) if fault_status[:faulted]

        fault_status[:faulted] = true
        raise 'fault!'
      end
    end

    def fail_sql_matching(regex)
      proc do
        allow(migration_context.connection).to receive(:execute).and_call_original
        allow(migration_context.connection).to receive(:execute).with(regex).and_wrap_original(&fail_first_time)
      end
    end

    def fail_adding_fk(from_table, to_table)
      proc do
        allow(migration_context.connection).to receive(:add_foreign_key).and_call_original
        expect(migration_context.connection).to receive(:add_foreign_key).with(from_table, to_table, any_args)
                                                                         .and_wrap_original(&fail_first_time)
      end
    end

    def fail_adding_concurrent_fk(from_table, to_table)
      proc do
        allow(migration_context).to receive(:add_concurrent_foreign_key).and_call_original
        expect(migration_context).to receive(:add_concurrent_foreign_key).with(from_table, to_table, any_args)
                                                                         .and_wrap_original(&fail_first_time)
      end
    end

    def fail_removing_fk(from_table, to_table)
      proc do
        allow(migration_context.connection).to receive(:remove_foreign_key).and_call_original
        expect(migration_context.connection).to receive(:remove_foreign_key).with(from_table, to_table, any_args)
                                                                            .and_wrap_original(&fail_first_time)
      end
    end
  end
end
