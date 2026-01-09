# frozen_string_literal: true

RSpec.shared_examples 'visible participants for issuable with read ability' do |model_class|
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

      instance.visible_participants(user1)
    end

    context 'with remove_per_source_permission_from_participants disabled' do
      before do
        stub_feature_flags(remove_per_source_permission_from_participants: false)
      end

      it 'receives expected ability' do
        source = ability_source == :participable_source ? participable_source : instance

        allow(instance).to receive(:bar).and_return(participable_source)
        allow(Ability).to receive(:allowed?).with(anything, ability_name, source)

        result = instance.visible_participants(user1)

        expect(Ability).to have_received(:allowed?).with(user1, ability_name, source)
        expect(result).to be_empty
      end
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
