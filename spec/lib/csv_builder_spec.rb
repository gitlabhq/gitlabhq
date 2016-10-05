require 'spec_helper'

describe CsvBuilder, lib: true do
  let(:object) { double(question: :answer) }
  let(:subject) { CsvBuilder.new('Q & A' => :question, 'Reversed' => -> (o) { o.question.to_s.reverse }) }
  let(:csv_data) { subject.render([object]) }

  it 'generates a csv' do
    expect(csv_data.scan(/(,|\n)/).join).to include ",\n,"
  end

  it 'uses hash keys as headers' do
    expect(csv_data).to start_with 'Q & A'
  end

  it 'gets data by calling method provided as hash value' do
    expect(csv_data).to include 'answer'
  end

  it 'allows lamdas to look up more complicated data' do
    expect(csv_data).to include 'rewsna'
  end
end
