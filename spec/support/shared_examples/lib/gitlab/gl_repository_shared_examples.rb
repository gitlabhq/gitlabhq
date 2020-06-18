# frozen_string_literal: true

RSpec.shared_examples 'parsing gl_repository identifier' do
  subject { described_class.new(identifier) }

  it 'returns correct information' do
    aggregate_failures do
      expect(subject.repo_type).to eq(expected_type)
      expect(subject.fetch_container!).to eq(expected_container)
    end
  end
end
