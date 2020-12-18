# frozen_string_literal: true

module Database
  module TriggerHelpers
    def expect_function_to_exist(name)
      expect(find_function_def(name)).not_to be_nil
    end

    def expect_function_not_to_exist(name)
      expect(find_function_def(name)).to be_nil
    end

    def expect_function_to_contain(name, *statements)
      return_stmt, *body_stmts = parsed_function_statements(name).reverse

      expect(return_stmt).to eq('return old')
      expect(body_stmts).to contain_exactly(*statements)
    end

    def expect_trigger_not_to_exist(table_name, name)
      expect(find_trigger_def(table_name, name)).to be_nil
    end

    def expect_valid_function_trigger(table_name, name, fn_name, fires_on)
      events, timing, definition = cleaned_trigger_def(table_name, name)

      events = events&.split(',')
      expected_timing, expected_events = fires_on.first
      expect(timing).to eq(expected_timing.to_s)
      expect(events).to match_array(Array.wrap(expected_events))

      expect(definition).to match(%r{execute (?:procedure|function) #{fn_name}()})
    end

    private

    def parsed_function_statements(name)
      cleaned_definition = find_function_def(name)['body'].downcase.gsub(/\s+/, ' ')
      statements = cleaned_definition.sub(/\A\s*begin\s*(.*)\s*end\s*\Z/, "\\1")
      statements.split(';').map! { |stmt| stmt.strip.presence }.compact!
    end

    def find_function_def(name)
      connection.select_one(<<~SQL)
        SELECT prosrc AS body
        FROM pg_proc
        WHERE proname = '#{name}'
      SQL
    end

    def cleaned_trigger_def(table_name, name)
      find_trigger_def(table_name, name).values_at('event', 'action_timing', 'action_statement').map!(&:downcase)
    end

    def find_trigger_def(table_name, name)
      connection.select_one(<<~SQL)
        SELECT
          string_agg(event_manipulation, ',') AS event,
          action_timing,
          action_statement
        FROM information_schema.triggers
        WHERE event_object_table = '#{table_name}'
        AND trigger_name = '#{name}'
        GROUP BY 2, 3
      SQL
    end
  end
end
