# frozen_string_literal: true

RSpec.shared_examples 'a repo type' do
  describe '#name' do
    it 'returns a symbol' do
      expect(subject.name).to be_a(Symbol)
    end
  end

  describe '#type_id' do
    it 'returns a string' do
      expect(subject.type_id).to be_a(String)
    end
  end

  describe

  describe '#identifier_for_container' do
    it 'returns expected identifier' do
      identifier = subject.identifier_for_container(expected_container)

      expect(identifier).to eq(expected_identifier)
    end
  end

  describe '#path_suffix' do
    it 'returns expected path_suffix' do
      expect(subject.path_suffix).to eq(expected_suffix)
    end
  end

  describe '#repository_for' do
    it 'finds the repository for the repo type' do
      expect(subject.repository_for(expected_container)).to eq(expected_repository)
    end

    it 'returns nil when container is nil' do
      expect(subject.repository_for(nil)).to eq(nil)
    end
  end
end
