require 'spec_helper'

describe CsvBuilder, lib: true do
  let(:object) { double(question: :answer) }
  let(:fake_relation) { [object] }
  let(:subject) { CsvBuilder.new(fake_relation, 'Q & A' => :question, 'Reversed' => -> (o) { o.question.to_s.reverse }) }
  let(:csv_data) { subject.render }

  before do
    allow(fake_relation).to receive(:find_each).and_yield(object)
  end

  it 'generates a csv' do
    expect(csv_data.scan(/(,|\n)/).join).to include ",\n,"
  end

  it 'uses a temporary file to reduce memory allocation' do
    expect(CSV).to receive(:new).with(instance_of(Tempfile)).and_call_original

    subject.render
  end

  it 'avoids loading all data in a single query' do
    expect(fake_relation).to receive(:find_each)

    subject.render
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
