# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillLanguageIdOnProgrammingLanguages, feature_category: :source_code_management do
  let(:programming_languages) { table(:programming_languages) }
  let(:mapping) { YAML.safe_load_file(Rails.root.join('vendor/languages.yml')) }

  describe '#up' do
    it 'backfills language_id from vendor/languages.yml', :aggregate_failures do
      ruby = programming_languages.create!(name: 'Ruby', color: '#701516', created_at: Time.current)
      js = programming_languages.create!(name: 'JavaScript', color: '#f1e05a', created_at: Time.current)

      expect(ruby.language_id).to be_nil
      expect(js.language_id).to be_nil

      migrate!

      expect(ruby.reload.language_id).to eq(mapping.dig('Ruby', 'language_id'))
      expect(js.reload.language_id).to eq(mapping.dig('JavaScript', 'language_id'))
    end

    it 'does not overwrite existing language_id values' do
      ruby = programming_languages.create!(name: 'Ruby', color: '#701516', language_id: 999, created_at: Time.current)

      migrate!

      expect(ruby.reload.language_id).to eq(999)
    end

    it 'handles languages not in vendor/languages.yml' do
      unknown = programming_languages.create!(name: 'UnknownLang', color: '#000000', created_at: Time.current)

      migrate!

      expect(unknown.reload.language_id).to be_nil
    end

    it 'does not fail when vendor/languages.yml is missing' do
      ruby = programming_languages.create!(name: 'Ruby', color: '#701516', created_at: Time.current)

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(Rails.root.join('vendor/languages.yml')).and_return(false)

      migrate!

      expect(ruby.reload.language_id).to be_nil
    end

    it 'does not fail when vendor/languages.yml is invalid' do
      ruby = programming_languages.create!(name: 'Ruby', color: '#701516', created_at: Time.current)

      allow(YAML).to receive(:safe_load_file).and_call_original
      allow(YAML).to receive(:safe_load_file)
        .with(Rails.root.join('vendor/languages.yml'))
        .and_raise(Psych::SyntaxError.new(nil, 1, 1, nil, 'invalid yaml', nil))

      migrate!

      expect(ruby.reload.language_id).to be_nil
    end
  end
end
