# frozen_string_literal: true

RSpec.shared_examples 'Notes::ActiveRecord' do
  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:updated_by).class_name('User') }

    it { is_expected.to have_many(:todos) }
  end

  describe 'validation' do
    it { is_expected.to validate_length_of(:note).is_at_most(1_000_000) }
    it { is_expected.to validate_presence_of(:note) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(AfterCommitQueue) }
    it { is_expected.to include_module(CacheMarkdownField) }
    it { is_expected.to include_module(Redactable) }
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Mentionable) }
    it { is_expected.to include_module(Awardable) }
    it { is_expected.to include_module(ResolvableNote) }
    it { is_expected.to include_module(Editable) }
    it { is_expected.to include_module(Sortable) }
  end
end
