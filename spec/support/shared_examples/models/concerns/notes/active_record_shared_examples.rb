# frozen_string_literal: true

RSpec.shared_examples 'Notes::ActiveRecord' do
  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:updated_by).class_name('User') }

    it { is_expected.to have_many(:todos) }
  end

  describe 'validation' do
    subject(:note) { build(factory) }

    before do
      allow(Gitlab::CurrentSettings).to receive(:description_and_note_max_size).and_return(1)
    end

    it 'validates note size' do
      is_expected.to validate_length_of(:note).is_at_most(Gitlab::CurrentSettings.description_and_note_max_size)
        .with_message("is too long (2 B). The maximum size is 1 B.")
    end

    it 'skips size validation when note is unchanged' do
      note.note = 'over limit'
      is_expected.not_to be_valid

      note.save!(validate: false)

      is_expected.to be_valid
    end

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
