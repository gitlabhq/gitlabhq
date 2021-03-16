# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BulkUpdate do
  describe 'error states' do
    let(:columns) { %i[title] }

    let_it_be(:mapping) do
      create_default(:user)
      create_default(:project)

      i_a, i_b = create_list(:issue, 2)

      {
        i_a => { title: 'Issue a' },
        i_b => { title: 'Issue b' }
      }
    end

    it 'does not raise errors on valid inputs' do
      expect { described_class.execute(columns, mapping) }.not_to raise_error
    end

    it 'expects a non-empty list of column names' do
      expect { described_class.execute([], mapping) }.to raise_error(ArgumentError)
    end

    it 'expects all columns to be symbols' do
      expect { described_class.execute([1], mapping) }.to raise_error(ArgumentError)
    end

    it 'expects all columns to be valid columns on the tables' do
      expect { described_class.execute([:foo], mapping) }.to raise_error(ArgumentError)
    end

    it 'refuses to set ID' do
      expect { described_class.execute([:id], mapping) }.to raise_error(ArgumentError)
    end

    it 'expects a non-empty mapping' do
      expect { described_class.execute(columns, []) }.to raise_error(ArgumentError)
    end

    it 'expects all map values to be Hash instances' do
      bad_map = mapping.merge(build(:issue) => 2)

      expect { described_class.execute(columns, bad_map) }.to raise_error(ArgumentError)
    end
  end

  it 'is possible to update all objects in a single query' do
    users = create_list(:user, 3)
    mapping = users.zip(%w[foo bar baz]).to_h do |u, name|
      [u, { username: name, admin: true }]
    end

    expect do
      described_class.execute(%i[username admin], mapping)
    end.not_to exceed_query_limit(1)

    # We have optimistically updated the values
    expect(users).to all(be_admin)
    expect(users.map(&:username)).to eq(%w[foo bar baz])

    users.each(&:reset)

    # The values are correct on reset
    expect(users).to all(be_admin)
    expect(users.map(&:username)).to eq(%w[foo bar baz])
  end

  it 'is possible to update heterogeneous sets' do
    create_default(:user)
    create_default(:project)

    mr_a = create(:merge_request)
    i_a, i_b = create_list(:issue, 2)

    mapping = {
      mr_a => { title: 'MR a' },
      i_a => { title: 'Issue a' },
      i_b => { title: 'Issue b' }
    }

    expect do
      described_class.execute(%i[title], mapping)
    end.not_to exceed_query_limit(2)

    expect([mr_a, i_a, i_b].map { |x| x.reset.title })
      .to eq(['MR a', 'Issue a', 'Issue b'])
  end

  shared_examples 'basic functionality' do
    it 'sets multiple values' do
      create_default(:user)
      create_default(:project)

      i_a, i_b = create_list(:issue, 2)

      mapping = {
        i_a => { title: 'Issue a' },
        i_b => { title: 'Issue b' }
      }

      described_class.execute(%i[title], mapping)

      expect([i_a, i_b].map { |x| x.reset.title })
        .to eq(['Issue a', 'Issue b'])
    end
  end

  include_examples 'basic functionality'

  context 'when prepared statements are configured differently to the normal test environment' do
    before do
      klass = Class.new(ActiveRecord::Base) do
        def self.abstract_class?
          true # So it gets its own connection
        end
      end

      stub_const('ActiveRecordBasePreparedStatementsInverted', klass)

      c = ActiveRecord::Base.connection.instance_variable_get(:@config)
      inverted = c.merge(prepared_statements: !ActiveRecord::Base.connection.prepared_statements)
      ActiveRecordBasePreparedStatementsInverted.establish_connection(inverted)

      allow(ActiveRecord::Base).to receive(:connection_specification_name)
        .and_return(ActiveRecordBasePreparedStatementsInverted.connection_specification_name)
    end

    include_examples 'basic functionality'
  end
end
