# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhereComposite do
  describe '.where_composite' do
    let_it_be(:test_table_name) { "_test_table_where_composite" }

    let(:model) do
      tbl_name = test_table_name
      Class.new(ApplicationRecord) do
        self.table_name = tbl_name

        include WhereComposite
      end
    end

    def connection
      ApplicationRecord.connection
    end

    before_all do
      connection.create_table(test_table_name) do |t|
        t.integer :foo
        t.integer :bar
        t.string  :wibble
      end
    end

    it 'requires at least one permitted key' do
      expect { model.where_composite([], nil) }
        .to raise_error(ArgumentError)
    end

    it 'requires all arguments to match the permitted_keys' do
      expect { model.where_composite([:foo], [{ foo: 1 }, { bar: 2 }]) }
        .to raise_error(ArgumentError)
    end

    it 'attaches a key error as cause if a key is missing' do
      expect { model.where_composite([:foo], [{ foo: 1 }, { bar: 2 }]) }
        .to raise_error(have_attributes(cause: KeyError))
    end

    it 'returns an empty relation if there are no arguments' do
      expect(model.where_composite([:foo, :bar], nil))
        .to be_empty

      expect(model.where_composite([:foo, :bar], []))
        .to be_empty
    end

    it 'permits extra arguments' do
      a = model.where_composite([:foo, :bar], { foo: 1, bar: 2 })
      b = model.where_composite([:foo, :bar], { foo: 1, bar: 2, baz: 3 })

      expect(a.to_sql).to eq(b.to_sql)
    end

    it 'can handle multiple fields' do
      fields = [:foo, :bar, :wibble]
      args = { foo: 1, bar: 2, wibble: 'wobble' }
      pattern = %r{
        WHERE \s+
          \(?
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s+ AND
             \s+ "#{test_table_name}"\."wibble" \s* = \s* 'wobble'
             \s*
          \)?
      }x

      expect(model.where_composite(fields, args).to_sql).to match(pattern)
    end

    it 'is equivalent to ids.map { |attrs| model.find_by(attrs) }' do
      10.times do |i|
        10.times do |j|
          model.create!(foo: i, bar: j, wibble: generate(:filename))
        end
      end

      ids = [{ foo: 1, bar: 9 }, { foo: 9, bar: 1 }]

      found = model.where_composite(%i[foo bar], ids)

      expect(found).to match_array(ids.map { |attrs| model.find_by!(attrs) })
    end

    it 'constructs (A&B) for one argument' do
      fields = [:foo, :bar]
      args = [
        { foo: 1, bar: 2 }
      ]
      pattern = %r{
        WHERE \s+
          \(?
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s*
          \)?
      }x

      expect(model.where_composite(fields, args).to_sql).to match(pattern)
      expect(model.where_composite(fields, args[0]).to_sql).to match(pattern)
    end

    it 'constructs (A&B) OR (C&D) for two arguments' do
      args = [
        { foo: 1, bar: 2 },
        { foo: 3, bar: 4 }
      ]
      pattern = %r{
        WHERE \s+
          \( \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 3
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 4
              \s* \)
      }x

      q = model.where_composite([:foo, :bar], args)

      expect(q.to_sql).to match(pattern)
    end

    it 'constructs (A&B) OR (C&D) OR (E&F) for three arguments' do
      args = [
        { foo: 1, bar: 2 },
        { foo: 3, bar: 4 },
        { foo: 5, bar: 6 }
      ]
      pattern = %r{
        WHERE \s+
          \({2}
             \s* "#{test_table_name}"\."foo" \s* = \s* 1
             \s+ AND
             \s+ "#{test_table_name}"\."bar" \s* = \s* 2
             \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 3
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 4
              \s* \)?
          \s* OR \s*
          \(? \s* "#{test_table_name}"\."foo" \s* = \s* 5
              \s+ AND
              \s+ "#{test_table_name}"\."bar" \s* = \s* 6
              \s* \)
      }x

      q = model.where_composite([:foo, :bar], args)

      expect(q.to_sql).to match(pattern)
    end

    describe 'large sets of IDs' do
      def query(size)
        args = (0..).lazy.take(size).map { |n| { foo: n, bar: n * n, wibble: 'x' * n } }.to_a
        model.where_composite([:foo, :bar, :wibble], args)
      end

      it 'constructs correct trees of constraints' do
        n = described_class::TooManyIds::LIMIT
        q = query(n)
        sql = q.to_sql

        expect(sql.scan(/OR/).count).to eq(n - 1)
        expect(sql.scan(/AND/).count).to eq(2 * n)
      end

      it 'raises errors if too many IDs are passed' do
        expect { query(described_class::TooManyIds::LIMIT + 1) }.to raise_error(described_class::TooManyIds)
      end
    end
  end
end
