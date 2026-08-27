# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::ProgrammingLanguagesImporter,
  feature_category: :source_code_management do
  describe '.import' do
    subject(:import_languages) { described_class.import }

    let(:yaml_path) { Rails.root.join('vendor/languages.yml') }
    let(:vendor_languages) do
      {
        'Ruby' => { 'language_id' => 326, 'color' => '#701516' },
        'JavaScript' => { 'language_id' => 183, 'color' => '#f1e05a' }
      }
    end

    before do
      allow(YAML).to receive(:safe_load_file).and_call_original
      allow(YAML).to receive(:safe_load_file).with(yaml_path).and_return(vendor_languages)
    end

    context 'when the table is empty' do
      it 'imports the exact vendor attributes' do
        import_languages

        expect(ProgrammingLanguage.pluck(:language_id, :name, :color)).to match_array([
          [326, 'Ruby', '#701516'],
          [183, 'JavaScript', '#f1e05a']
        ])
      end
    end

    context 'when a definition has language ID zero' do
      let(:vendor_languages) do
        { 'Unknown' => { 'language_id' => 0, 'color' => '#000000' } }
      end

      it 'imports the definition' do
        expect { import_languages }.to change { ProgrammingLanguage.where(language_id: 0).count }.from(0).to(1)
      end
    end

    context 'when a stable ID row has stale vendor attributes' do
      it 'updates the row without changing either ID', :aggregate_failures do
        language = create(:programming_language, language_id: 326, name: 'Old Ruby', color: '#ffffff')
        local_id = language.id

        import_languages
        language.reload

        expect(language).to have_attributes(name: 'Ruby', color: '#701516')
        expect(language.id).to eq(local_id)
        expect(language.language_id).to eq(326)
      end
    end

    context 'when run repeatedly' do
      it 'does not create duplicates or change canonical values', :aggregate_failures do
        import_languages
        original_rows = ProgrammingLanguage.pluck(:id, :language_id, :name, :color)

        expect(ProgrammingLanguage).not_to receive(:upsert_all)

        described_class.import

        expect(ProgrammingLanguage.count).to eq(original_rows.size)
        expect(ProgrammingLanguage.pluck(:id, :language_id, :name, :color)).to match_array(original_rows)
      end
    end

    context 'when unrelated rows exist' do
      it 'leaves them untouched' do
        unrelated_language = create(:programming_language, language_id: 999, name: 'Unrelated', color: '#abcdef')

        expect { import_languages }.not_to change { unrelated_language.reload.attributes }
      end
    end

    context 'when definitions are incomplete' do
      let(:vendor_languages) do
        {
          'No ID' => { 'color' => '#123456' },
          'No color' => { 'language_id' => 1 },
          'Nil color' => { 'language_id' => 2, 'color' => nil },
          'Blank color' => { 'language_id' => 3, 'color' => ' ' },
          'Complete' => { 'language_id' => 4, 'color' => '#654321' }
        }
      end

      it 'skips missing IDs and missing or blank colors' do
        import_languages

        expect(ProgrammingLanguage.pluck(:language_id, :name, :color))
          .to contain_exactly([4, 'Complete', '#654321'])
      end
    end

    context 'when a vendor name belongs to a different stable ID row' do
      it 'preserves both conflicting rows and imports other definitions', :aggregate_failures do
        id_match = create(:programming_language, language_id: 326, name: 'Old Ruby', color: '#ffffff')
        name_match = create(:programming_language, language_id: 999, name: 'Ruby', color: '#000000')

        import_languages

        expect(id_match.reload).to have_attributes(language_id: 326, name: 'Old Ruby', color: '#ffffff')
        expect(name_match.reload).to have_attributes(language_id: 999, name: 'Ruby', color: '#000000')
        expect(ProgrammingLanguage.find_by(language_id: 183))
          .to have_attributes(name: 'JavaScript', color: '#f1e05a')
      end
    end

    context 'when a vendor name exists without a matching stable ID row' do
      it 'preserves the name match and imports other definitions', :aggregate_failures do
        name_match = create(:programming_language, language_id: 999, name: 'Ruby', color: '#000000')

        expect { import_languages }.not_to raise_error

        expect(name_match.reload).to have_attributes(language_id: 999, name: 'Ruby', color: '#000000')
        expect(ProgrammingLanguage.where(name: 'Ruby').pluck(:language_id)).to match_array([999])
        expect(ProgrammingLanguage.find_by(language_id: 326)).to be_nil
        expect(ProgrammingLanguage.find_by(language_id: 183))
          .to have_attributes(name: 'JavaScript', color: '#f1e05a')
      end
    end

    context 'when a vendor name differs only by case from a different stable ID row' do
      it 'imports both case-sensitive names and other definitions', :aggregate_failures do
        name_match = create(:programming_language, language_id: 999, name: 'ruby', color: '#000000')

        import_languages

        expect(name_match.reload).to have_attributes(language_id: 999, name: 'ruby', color: '#000000')
        expect(ProgrammingLanguage.find_by(language_id: 326))
          .to have_attributes(language_id: 326, name: 'Ruby', color: '#701516')
        expect(ProgrammingLanguage.where(name: %w[ruby Ruby]).pluck(:language_id, :name))
          .to match_array([[999, 'ruby'], [326, 'Ruby']])
        expect(ProgrammingLanguage.find_by(language_id: 183))
          .to have_attributes(name: 'JavaScript', color: '#f1e05a')
      end
    end

    context 'when a vendor name belongs to a legacy row without a stable ID' do
      it 'preserves the legacy row and imports other definitions', :aggregate_failures do
        name_match = create(:programming_language, language_id: nil, name: 'Ruby', color: '#000000')

        expect { import_languages }.not_to raise_error

        expect(name_match.reload).to have_attributes(language_id: nil, name: 'Ruby', color: '#000000')
        expect(ProgrammingLanguage.where(name: 'Ruby').pluck(:language_id)).to match_array([nil])
        expect(ProgrammingLanguage.find_by(language_id: 326)).to be_nil
        expect(ProgrammingLanguage.find_by(language_id: 183))
          .to have_attributes(name: 'JavaScript', color: '#f1e05a')
      end
    end
  end
end
