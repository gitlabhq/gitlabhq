# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LanguageDetection do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
  let_it_be(:haskell) { create(:programming_language, name: 'Haskell') }

  let(:repository) { project.repository }
  let(:detection) do
    [{ value: 66.63, label: "Ruby", color: "#701516", highlight: "#701516", language_id: 326 },
      { value: 12.96, label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a", language_id: 183 },
      { value: 7.9, label: "Elixir", color: "#e34c26", highlight: "#e34c26", language_id: 104 },
      { value: 2.51, label: "CoffeeScript", color: "#244776", highlight: "#244776", language_id: 63 },
      { value: 1.51, label: "Go", color: "#2a4776", highlight: "#244776", language_id: 132 },
      { value: 1.1, label: "MepmepLang", color: "#2a4776", highlight: "#244776", language_id: 999 }]
  end

  let(:repository_languages) do
    [RepositoryLanguage.new(share: 10, programming_language: ruby)]
  end

  subject { described_class.new(repository, repository_languages) }

  before do
    allow(repository).to receive(:languages).and_return(detection)
  end

  describe '#languages' do
    it 'returns the language names' do
      expect(subject.languages).to eq(%w[Ruby JavaScript Elixir CoffeeScript Go])
    end
  end

  describe '#language_gitaly_id' do
    subject { described_class.new(repository, repository_languages).language_gitaly_id(name) }

    context 'when the language is detected' do
      let(:name) { 'Ruby' }

      it { is_expected.to eq(326) }
    end

    context 'when the language is not detected' do
      let(:name) { 'Unknown' }

      it { is_expected.to be_nil }
    end
  end

  describe '#insertions' do
    let(:programming_languages) { [ruby, haskell] }
    let(:detection) do
      [{ value: 10, label: haskell.name, color: haskell.color, language_id: 150 }]
    end

    it 'only includes new languages' do
      insertions = subject.insertions(programming_languages)

      expect(insertions).not_to be_empty
      expect(insertions.first[:project_id]).to be(project.id)
      expect(insertions.first[:programming_language_id]).to be(haskell.id)
      expect(insertions.first[:share]).to be(10)
    end
  end

  describe '#updates' do
    it 'updates the share of languages' do
      first_update = subject.updates.first

      expect(first_update).not_to be_nil
      expect(first_update[:programming_language_id]).to eq(ruby.id)
      expect(first_update[:share]).to eq(66.63)
    end

    it 'does not include languages to be removed' do
      ids = subject.updates.map { |h| h[:programming_language_id] }

      expect(ids).not_to include(haskell.id)
    end

    context 'when silent writes occur' do
      let(:repository_languages) do
        [RepositoryLanguage.new(share: 66.63, programming_language: ruby)]
      end

      it "doesn't include them in the result" do
        expect(subject.updates).to be_empty
      end
    end
  end

  describe '#deletions' do
    let(:repository_languages) do
      [RepositoryLanguage.new(share: 10, programming_language: ruby),
        RepositoryLanguage.new(share: 5, programming_language: haskell)]
    end

    it 'lists undetected languages' do
      expect(subject.deletions).not_to be_empty
      expect(subject.deletions).to include(haskell.id)
    end
  end
end
