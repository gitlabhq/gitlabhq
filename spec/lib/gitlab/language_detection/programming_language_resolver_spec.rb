# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LanguageDetection::ProgrammingLanguageResolver, feature_category: :source_code_management do
  subject(:resolved_languages) { described_class.new(detected_languages).execute }

  describe '#execute' do
    context 'when all detected languages are current' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby', color: '#701516', language_id: 326) }
      let_it_be(:javascript) { create(:programming_language, name: 'JavaScript', color: '#f1e05a', language_id: 158) }

      let(:detected_languages) do
        [
          detected_language(name: 'Ruby', color: '#701516', language_id: 326),
          detected_language(name: 'JavaScript', color: '#f1e05a', language_id: 158)
        ]
      end

      it 'returns the existing languages without changing records', :aggregate_failures do
        languages = nil
        ruby_attributes = ruby.reload.attributes
        javascript_attributes = javascript.reload.attributes

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(languages).to contain_exactly(ruby, javascript)
        expect(ruby.reload.attributes).to eq(ruby_attributes)
        expect(javascript.reload.attributes).to eq(javascript_attributes)
      end
    end

    context 'when an existing language matches by language_id with an old name' do
      let_it_be(:language) do
        create(:programming_language, name: 'Mathematica', color: '#dd1100', language_id: 224)
      end

      let(:detected_languages) do
        [detected_language(name: 'Wolfram Language', color: '#123456', language_id: 224)]
      end

      it 'updates and returns the existing language', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(languages).to contain_exactly(language)
        expect(language.reload).to have_attributes(
          name: 'Wolfram Language',
          color: '#123456',
          language_id: 224
        )
      end
    end

    context 'when an existing language matches by name with a missing language_id' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby', color: '#701516', language_id: nil) }

      let(:detected_languages) do
        [detected_language(name: 'Ruby', color: '#701516', language_id: 326)]
      end

      it 'updates and returns the existing language', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(languages).to contain_exactly(ruby)
        expect(ruby.reload).to have_attributes(
          name: 'Ruby',
          color: '#701516',
          language_id: 326
        )
      end
    end

    context 'when some detected languages are missing' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }

      let(:detected_languages) do
        [
          detected_language(name: 'Ruby', color: '#701516', language_id: 326),
          detected_language(name: 'NewLang', color: '#abcdef', language_id: 12345)
        ]
      end

      it 'creates the missing languages and returns existing and created languages', :aggregate_failures do
        expect { resolved_languages }.to change { ProgrammingLanguage.count }.by(1)

        new_language = ProgrammingLanguage.find_by!(name: 'NewLang')
        expect(new_language.color).to eq('#abcdef')
        expect(new_language.language_id).to eq(12345)
        expect(resolved_languages).to contain_exactly(ruby, new_language)
      end
    end

    context 'when the detected name and language_id match different existing languages' do
      let_it_be(:language_by_id) do
        create(:programming_language, name: 'Mathematica', color: '#dd1100', language_id: 224)
      end

      let_it_be(:language_by_name) do
        create(:programming_language, name: 'Wolfram Language', color: '#abcdef', language_id: 10_224)
      end

      let(:detected_languages) do
        [detected_language(name: 'Wolfram Language', color: '#123456', language_id: 224)]
      end

      it 'returns the language_id match without changing either language', :aggregate_failures do
        languages = nil

        language_by_id_attributes = language_by_id.reload.attributes
        language_by_name_attributes = language_by_name.reload.attributes

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(languages).to contain_exactly(language_by_id)
        expect(language_by_id.reload.attributes).to eq(language_by_id_attributes)
        expect(language_by_name.reload.attributes).to eq(language_by_name_attributes)
      end
    end

    context 'when creating a detected language raises RecordNotUnique' do
      let(:detected_languages) do
        [detected_language(name: 'Wolfram Language', color: '#dd1100', language_id: 224)]
      end

      before do
        stub_create_conflict_for('Wolfram Language')
        allow(ProgrammingLanguage).to receive(:find_by).and_call_original
      end

      it 'returns a language_id match before falling back to name' do
        language_by_id = instance_double(ProgrammingLanguage)

        expect(ProgrammingLanguage).to receive(:find_by)
          .with(language_id: 224)
          .and_return(language_by_id)
        expect(ProgrammingLanguage).not_to receive(:find_by)
          .with(name: 'Wolfram Language')

        expect(resolved_languages).to contain_exactly(language_by_id)
      end

      it 'falls back to a name match when a language_id match does not exist' do
        language_by_name = instance_double(ProgrammingLanguage)

        expect(ProgrammingLanguage).to receive(:find_by)
          .with(language_id: 224)
          .and_return(nil)
        expect(ProgrammingLanguage).to receive(:find_by)
          .with(name: 'Wolfram Language')
          .and_return(language_by_name)

        expect(resolved_languages).to contain_exactly(language_by_name)
      end
    end

    context 'when detected_languages is empty' do
      let(:detected_languages) { [] }

      it 'returns an empty result without creating records', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages }.not_to change { ProgrammingLanguage.count }

        expect(languages).to be_empty
      end
    end
  end

  def detected_language(name:, color:, language_id:)
    Gitlab::LanguageDetection::DetectedLanguage.new(
      name: name,
      share: 100.0,
      color: color,
      language_id: language_id
    )
  end

  def stub_create_conflict_for(name)
    relation = instance_double(ActiveRecord::Relation)

    allow(ProgrammingLanguage).to receive(:where).and_call_original
    allow(ProgrammingLanguage).to receive(:where)
      .with(name: name)
      .and_return(relation)
    allow(relation).to receive(:first_or_create)
      .and_raise(ActiveRecord::RecordNotUnique)
  end
end
