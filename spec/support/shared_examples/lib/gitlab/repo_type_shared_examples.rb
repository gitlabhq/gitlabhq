# frozen_string_literal: true

RSpec.shared_examples 'a repo type' do
  describe '#identifier_for_container' do
    subject { described_class.identifier_for_container(expected_container) }

    it { is_expected.to eq(expected_identifier) }
  end

  describe '#path_suffix' do
    subject { described_class.path_suffix }

    it { is_expected.to eq(expected_suffix) }
  end

  describe '#repository_for' do
    it 'finds the repository for the repo type' do
      expect(described_class.repository_for(expected_repository_resolver)).to eq(expected_repository)
    end

    it 'returns nil when container is nil' do
      expect(described_class.repository_for(nil)).to eq(nil)
    end
  end
end
