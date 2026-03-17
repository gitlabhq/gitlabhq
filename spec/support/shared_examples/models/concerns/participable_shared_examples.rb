# frozen_string_literal: true

RSpec.shared_examples 'participants for issuable with read ability' do |model_class|
  let(:model) { model_class.to_s.classify.constantize }

  before do
    allow(Ability).to receive(:allowed?).with(anything, :"read_#{model_class}", anything).and_return(true)
    allow(model).to receive(:participant_attrs).and_return([:bar])
  end

  shared_examples 'check for participables read ability' do |ability_name, ability_source: nil|
    it 'bypasses per-source permission checks' do
      source = ability_source == :participable_source ? participable_source : instance

      allow(instance).to receive(:bar).and_return(participable_source)

      expect(Ability).not_to receive(:allowed?).with(anything, ability_name, source)

      instance.participants(user1)
    end
  end

  context 'when source is an award emoji' do
    let(:participable_source) { build(:award_emoji, :upvote) }

    it_behaves_like 'check for participables read ability', :read_issuable_participables
  end

  context 'when source is a note' do
    let(:participable_source) { build(:note) }

    it_behaves_like 'check for participables read ability', :read_note
  end

  context 'when source is an internal note' do
    let(:participable_source) { build(:note, :confidential) }

    it_behaves_like 'check for participables read ability', :read_internal_note
  end

  context 'when source is a system note' do
    let(:participable_source) { build(:system_note) }

    it_behaves_like 'check for participables read ability', :read_note, ability_source: :participable_source
  end
end
