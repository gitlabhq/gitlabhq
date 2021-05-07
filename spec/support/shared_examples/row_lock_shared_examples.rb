# frozen_string_literal: true

# Ensure that a SQL command to lock this row(s) was requested.
# Ensure a transaction also occurred.
# Be careful! This form of spec is not foolproof, but better than nothing.

RSpec.shared_examples 'locked row' do
  it "has locked row" do
    table_name = row.class.table_name
    ids_regex = /SELECT.*FROM.*#{table_name}.*"#{table_name}"."id" = #{row.id}.+FOR UPDATE/m

    expect(recorded_queries.log).to include a_string_matching 'SAVEPOINT'
    expect(recorded_queries.log).to include a_string_matching ids_regex
  end
end

RSpec.shared_examples 'locked rows' do
  it "has locked rows" do
    table_name = rows.first.class.table_name

    row_ids = rows.map(&:id).join(', ')
    ids_regex = /SELECT.+FROM.+"#{table_name}".+"#{table_name}"."id" IN \(#{row_ids}\).+FOR UPDATE/m

    expect(recorded_queries.log).to include a_string_matching 'SAVEPOINT'
    expect(recorded_queries.log).to include a_string_matching ids_regex
  end
end
