# frozen_string_literal: true

RSpec.shared_examples 'a repo type' do
  describe '#identifier_for_container' do
    subject { described_class.identifier_for_container(expected_container) }

    it { is_expected.to eq(expected_identifier) }
  end

  describe '#fetch_id' do
    it 'finds an id match in the identifier' do
      expect(described_class.fetch_id(expected_identifier)).to eq(expected_id)
    end

    it 'does not break on other identifiers' do
      expect(described_class.fetch_id('wiki-noid')).to eq(nil)
    end
  end

  describe '#fetch_container!' do
    it 'returns the container' do
      expect(described_class.fetch_container!(expected_identifier)).to eq expected_container
    end

    it 'raises an exception if the identifier is invalid' do
      expect { described_class.fetch_container!('project-noid') }.to raise_error ArgumentError
    end
  end

  describe '#path_suffix' do
    subject { described_class.path_suffix }

    it { is_expected.to eq(expected_suffix) }
  end

  describe '#repository_for' do
    it 'finds the repository for the repo type' do
      expect(described_class.repository_for(expected_container)).to eq(expected_repository)
    end
  end
end
