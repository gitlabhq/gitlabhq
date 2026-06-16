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
      expect(insertions.first[:language_id]).to eq(haskell.language_id)
    end

    context 'when programming language has no language_id' do
      let(:no_lang_id) { create(:programming_language, name: 'Elixir', language_id: nil) }
      let(:programming_languages) { [ruby, no_lang_id] }

      let(:detection) do
        [{ value: 10, label: 'Elixir', color: no_lang_id.color, language_id: 150 }]
      end

      it 'includes language_id as nil in the insertion hash' do
        insertions = subject.insertions(programming_languages)

        expect(insertions.first[:language_id]).to be_nil
      end
    end

    context 'when inserting multiple languages with mixed language_id presence' do
      let_it_be(:go_lang) { create(:programming_language, name: 'Go') }
      let_it_be(:elixir_no_lid) { create(:programming_language, name: 'Elixir', language_id: nil) }
      let(:programming_languages) { [ruby, go_lang, elixir_no_lid] }
      let(:repository_languages) { [] }

      let(:detection) do
        [
          { value: 50.0, label: 'Elixir', color: '#e34c26', highlight: '#e34c26', language_id: nil },
          { value: 30.0, label: 'Go', color: '#2a4776', highlight: '#2a4776', language_id: 132 }
        ]
      end

      it 'includes language_id for all insertions with consistent keys' do
        insertions = subject.insertions(programming_languages)

        expect(insertions.size).to eq(2)
        expect(insertions.map(&:keys).uniq.size).to eq(1)

        elixir_insert = insertions.find { |i| i[:programming_language_id] == elixir_no_lid.id }
        go_insert = insertions.find { |i| i[:programming_language_id] == go_lang.id }

        expect(elixir_insert[:language_id]).to be_nil
        expect(go_insert[:language_id]).to eq(go_lang.language_id)
      end
    end
  end

  describe '#updates' do
    it 'updates the share of languages' do
      first_update = subject.updates.first

      expect(first_update).not_to be_nil
      expect(first_update[:programming_language_id]).to eq(ruby.id)
      expect(first_update[:share]).to eq(66.63)
      expect(first_update[:language_id]).to eq(ruby.language_id)
    end

    it 'does not include languages to be removed' do
      ids = subject.updates.map { |h| h[:programming_language_id] }

      expect(ids).not_to include(haskell.id)
    end

    context 'when silent writes occur' do
      let(:repository_languages) do
        [RepositoryLanguage.new(share: 66.63, programming_language: ruby, language_id: ruby.language_id)]
      end

      it "doesn't include them in the result" do
        expect(subject.updates).to be_empty
      end
    end

    context 'when share is unchanged but language_id is missing' do
      let(:repository_languages) do
        [RepositoryLanguage.new(share: 66.63, programming_language: ruby, language_id: nil)]
      end

      it 'includes the row for update to populate language_id' do
        updates = subject.updates

        expect(updates).not_to be_empty
        expect(updates.first[:language_id]).to eq(ruby.language_id)
        expect(updates.first[:share]).to eq(66.63)
      end
    end

    context 'when share and language_id are both current' do
      let(:repository_languages) do
        [RepositoryLanguage.new(share: 66.63, programming_language: ruby, language_id: ruby.language_id)]
      end

      it 'does not include the row' do
        expect(subject.updates).to be_empty
      end
    end

    context 'when programming language has no language_id' do
      let(:ruby_no_lid) { create(:programming_language, name: 'Scala', language_id: nil) }

      let(:detection) do
        [{ value: 66.63, label: "Scala", color: "#701516", highlight: "#701516", language_id: 326 }]
      end

      let(:repository_languages) do
        [RepositoryLanguage.new(share: 10, programming_language: ruby_no_lid)]
      end

      it 'includes language_id as nil in the update hash' do
        first_update = subject.updates.first

        expect(first_update[:language_id]).to be_nil
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
