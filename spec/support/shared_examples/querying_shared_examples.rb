# frozen_string_literal: true

def update_column_regex(column)
  /UPDATE.+SET.+#{column}[^=*]=.+FROM.*/m
end

RSpec.shared_examples 'update on column' do |column|
  it "#{column} column updated" do
    qr = ActiveRecord::QueryRecorder.new do
      subject
    end
    expect(qr.log).to include a_string_matching update_column_regex(column)
  end
end

RSpec.shared_examples 'no update on column' do |column|
  it "#{column} column is not updated" do
    qr = ActiveRecord::QueryRecorder.new do
      subject
    end
    expect(qr.log).not_to include a_string_matching update_column_regex(column)
  end
end
