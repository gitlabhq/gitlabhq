# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryLanguage, feature_category: :source_code_management do
  subject(:repository_language) { build(:repository_language) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:programming_language) }

    it 'defines the stable programming language association' do
      is_expected.to belong_to(:stable_programming_language)
        .class_name('ProgrammingLanguage')
        .with_foreign_key(:language_id)
        .with_primary_key(:language_id)
        .optional
    end
  end

  describe '#resolved_programming_language' do
    let_it_be(:legacy_language) { create(:programming_language, name: 'Resolver legacy') }
    let_it_be(:stable_language) { create(:programming_language, name: 'Resolver stable') }

    subject(:resolved_programming_language) { repository_language.resolved_programming_language }

    context 'when language_id matches a programming language' do
      let(:repository_language) do
        build(:repository_language, programming_language: legacy_language, language_id: stable_language.language_id)
      end

      it { is_expected.to eq(stable_language) }
    end

    context 'when language_id is nil' do
      let(:repository_language) do
        build(:repository_language, programming_language: legacy_language, language_id: nil)
      end

      it { is_expected.to eq(legacy_language) }
    end

    context 'when language_id does not match a programming language' do
      let(:repository_language) do
        build(:repository_language, programming_language: legacy_language, language_id: non_existing_record_id)
      end

      it { is_expected.to eq(legacy_language) }
    end
  end

  describe 'delegated language attributes' do
    let_it_be(:legacy_language) { create(:programming_language, name: 'Legacy', color: '#111111') }
    let_it_be(:stable_language) { create(:programming_language, name: 'Stable', color: '#222222') }

    context 'when language_id matches a programming language' do
      let(:repository_language) do
        build(:repository_language, programming_language: legacy_language, language_id: stable_language.language_id)
      end

      it 'delegates name and color to the stable programming language', :aggregate_failures do
        expect(repository_language.name).to eq(stable_language.name)
        expect(repository_language.color).to eq(stable_language.color)
      end
    end

    context 'when language_id is nil' do
      let(:repository_language) do
        build(:repository_language, programming_language: legacy_language, language_id: nil)
      end

      it 'delegates name and color to the legacy programming language', :aggregate_failures do
        expect(repository_language.name).to eq(legacy_language.name)
        expect(repository_language.color).to eq(legacy_language.color)
      end
    end

    context 'when neither association resolves' do
      let(:repository_language) do
        build(:repository_language, programming_language: nil, language_id: non_existing_record_id)
      end

      it 'raises instead of returning nil' do
        expect { repository_language.name }.to raise_error(Module::DelegationError)
      end
    end
  end

  describe 'default scope' do
    let_it_be(:project) { create(:project) }
    let_it_be(:legacy_language) { create(:programming_language, name: 'Preload legacy') }
    let_it_be(:stable_language) { create(:programming_language, name: 'Preload stable') }
    let_it_be(:repository_language) do
      create(:repository_language,
        project: project,
        programming_language: legacy_language,
        language_id: stable_language.language_id)
    end

    it 'preloads the resolved programming language' do
      repository_languages = described_class.where(project: project).to_a

      expect { repository_languages.map(&:resolved_programming_language) }.not_to exceed_query_limit(0)
    end
  end

  describe 'validations' do
    it { is_expected.to allow_value(0).for(:share) }
    it { is_expected.to allow_value(100.0).for(:share) }
    it { is_expected.not_to allow_value(100.1).for(:share) }
    it { is_expected.to validate_uniqueness_of(:programming_language).scoped_to(:project_id) }
    it { is_expected.to validate_uniqueness_of(:language_id).scoped_to(:project_id).allow_nil }
  end
end
