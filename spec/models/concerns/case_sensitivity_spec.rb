require 'spec_helper'

describe CaseSensitivity do
  describe '.iwhere' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:model)      { Class.new { include CaseSensitivity } }

    describe 'using PostgreSQL' do
      before do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(true)
        allow(Gitlab::Database).to receive(:mysql?).and_return(false)
      end

      describe 'with a single column/value pair' do
        it 'returns the criteria for a column and a value' do
          criteria = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:foo)
            .and_return('"foo"')

          expect(model).to receive(:where)
            .with(%q{LOWER("foo") = LOWER(:value)}, value: 'bar')
            .and_return(criteria)

          expect(model.iwhere(foo: 'bar')).to eq(criteria)
        end

        it 'returns the criteria for a column with a table, and a value' do
          criteria = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.bar')
            .and_return('"foo"."bar"')

          expect(model).to receive(:where)
            .with(%q{LOWER("foo"."bar") = LOWER(:value)}, value: 'bar')
            .and_return(criteria)

          expect(model.iwhere('foo.bar'.to_sym => 'bar')).to eq(criteria)
        end
      end

      describe 'with multiple column/value pairs' do
        it 'returns the criteria for a column and a value' do
          initial = double(:criteria)
          final   = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:foo)
            .and_return('"foo"')

          expect(connection).to receive(:quote_table_name)
            .with(:bar)
            .and_return('"bar"')

          expect(model).to receive(:where)
            .with(%q{LOWER("foo") = LOWER(:value)}, value: 'bar')
            .and_return(initial)

          expect(initial).to receive(:where)
            .with(%q{LOWER("bar") = LOWER(:value)}, value: 'baz')
            .and_return(final)

          got = model.iwhere(foo: 'bar', bar: 'baz')

          expect(got).to eq(final)
        end

        it 'returns the criteria for a column with a table, and a value' do
          initial = double(:criteria)
          final   = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.bar')
            .and_return('"foo"."bar"')

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.baz')
            .and_return('"foo"."baz"')

          expect(model).to receive(:where)
            .with(%q{LOWER("foo"."bar") = LOWER(:value)}, value: 'bar')
            .and_return(initial)

          expect(initial).to receive(:where)
            .with(%q{LOWER("foo"."baz") = LOWER(:value)}, value: 'baz')
            .and_return(final)

          got = model.iwhere('foo.bar'.to_sym => 'bar',
                             'foo.baz'.to_sym => 'baz')

          expect(got).to eq(final)
        end
      end
    end

    describe 'using MySQL' do
      before do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(false)
        allow(Gitlab::Database).to receive(:mysql?).and_return(true)
      end

      describe 'with a single column/value pair' do
        it 'returns the criteria for a column and a value' do
          criteria = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:foo)
            .and_return('`foo`')

          expect(model).to receive(:where)
            .with(%q{`foo` = :value}, value: 'bar')
            .and_return(criteria)

          expect(model.iwhere(foo: 'bar')).to eq(criteria)
        end

        it 'returns the criteria for a column with a table, and a value' do
          criteria = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.bar')
            .and_return('`foo`.`bar`')

          expect(model).to receive(:where)
            .with(%q{`foo`.`bar` = :value}, value: 'bar')
            .and_return(criteria)

          expect(model.iwhere('foo.bar'.to_sym => 'bar'))
            .to eq(criteria)
        end
      end

      describe 'with multiple column/value pairs' do
        it 'returns the criteria for a column and a value' do
          initial = double(:criteria)
          final   = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:foo)
            .and_return('`foo`')

          expect(connection).to receive(:quote_table_name)
            .with(:bar)
            .and_return('`bar`')

          expect(model).to receive(:where)
            .with(%q{`foo` = :value}, value: 'bar')
            .and_return(initial)

          expect(initial).to receive(:where)
            .with(%q{`bar` = :value}, value: 'baz')
            .and_return(final)

          got = model.iwhere(foo: 'bar', bar: 'baz')

          expect(got).to eq(final)
        end

        it 'returns the criteria for a column with a table, and a value' do
          initial = double(:criteria)
          final   = double(:criteria)

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.bar')
            .and_return('`foo`.`bar`')

          expect(connection).to receive(:quote_table_name)
            .with(:'foo.baz')
            .and_return('`foo`.`baz`')

          expect(model).to receive(:where)
            .with(%q{`foo`.`bar` = :value}, value: 'bar')
            .and_return(initial)

          expect(initial).to receive(:where)
            .with(%q{`foo`.`baz` = :value}, value: 'baz')
            .and_return(final)

          got = model.iwhere('foo.bar'.to_sym => 'bar',
                             'foo.baz'.to_sym => 'baz')

          expect(got).to eq(final)
        end
      end
    end
  end
end
