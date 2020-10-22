# frozen_string_literal: true

RSpec.shared_examples 'a postgres model' do
  describe '.by_identifier' do
    it "finds the #{described_class}" do
      expect(find(identifier)).to be_a(described_class)
    end

    it 'raises an error if not found' do
      expect { find('public.idontexist') }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises ArgumentError if given a non-fully qualified identifier' do
      expect { find('foo') }.to raise_error(ArgumentError, /not fully qualified/)
    end
  end

  describe '#to_s' do
    it 'returns the name' do
      expect(find(identifier).to_s).to eq(name)
    end
  end

  describe '#schema' do
    it 'returns the schema' do
      expect(find(identifier).schema).to eq(schema)
    end
  end

  describe '#name' do
    it 'returns the name' do
      expect(find(identifier).name).to eq(name)
    end
  end
end
