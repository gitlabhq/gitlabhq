require 'spec_helper'

describe RspecFlaky::Example do
  let(:example_attrs) do
    {
      id: 'spec/foo/bar_spec.rb:2',
      metadata: {
        file_path: 'spec/foo/bar_spec.rb',
        line_number: 2,
        full_description: 'hello world'
      },
      execution_result: double(status: 'passed', exception: 'BOOM!'),
      attempts: 1
    }
  end
  let(:rspec_example) { double(example_attrs) }

  describe '#initialize' do
    shared_examples 'a valid Example instance' do
      it 'returns valid attributes' do
        example = described_class.new(args)

        expect(example.example_id).to eq(example_attrs[:id])
      end
    end

    context 'when given an Rspec::Core::Example that responds to #example' do
      let(:args) { double(example: rspec_example) }

      it_behaves_like 'a valid Example instance'
    end

    context 'when given an Rspec::Core::Example that does not respond to #example' do
      let(:args) { rspec_example }

      it_behaves_like 'a valid Example instance'
    end
  end

  subject { described_class.new(rspec_example) }

  describe '#uid' do
    it 'returns a hash of the full description' do
      expect(subject.uid).to eq(Digest::MD5.hexdigest("#{subject.description}-#{subject.file}"))
    end
  end

  describe '#example_id' do
    it 'returns the ID of the RSpec::Core::Example' do
      expect(subject.example_id).to eq(rspec_example.id)
    end
  end

  describe '#attempts' do
    it 'returns the attempts of the RSpec::Core::Example' do
      expect(subject.attempts).to eq(rspec_example.attempts)
    end
  end

  describe '#file' do
    it 'returns the metadata[:file_path] of the RSpec::Core::Example' do
      expect(subject.file).to eq(rspec_example.metadata[:file_path])
    end
  end

  describe '#line' do
    it 'returns the metadata[:line_number] of the RSpec::Core::Example' do
      expect(subject.line).to eq(rspec_example.metadata[:line_number])
    end
  end

  describe '#description' do
    it 'returns the metadata[:full_description] of the RSpec::Core::Example' do
      expect(subject.description).to eq(rspec_example.metadata[:full_description])
    end
  end

  describe '#status' do
    it 'returns the execution_result.status of the RSpec::Core::Example' do
      expect(subject.status).to eq(rspec_example.execution_result.status)
    end
  end

  describe '#exception' do
    it 'returns the execution_result.exception of the RSpec::Core::Example' do
      expect(subject.exception).to eq(rspec_example.execution_result.exception)
    end
  end
end
