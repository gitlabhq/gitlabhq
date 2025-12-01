# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Participable, feature_category: :team_planning do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group, :public) }

  let(:model) do
    Class.new do
      include Participable
    end
  end

  let(:instance) { model.new }

  describe '.participant' do
    it 'adds the participant attributes to the existing list' do
      model.participant(:foo)
      model.participant(:bar)

      expect(model.participant_attrs).to eq([:foo, :bar])
    end
  end

  describe '#participants' do
    it 'returns the list of participants without filtering' do
      model.participant(:foo)
      model.participant(:bar)

      expect(instance).to receive(:foo).and_return(user2)
      expect(instance).to receive(:bar).and_return(user3)
      expect(instance).to receive(:project).exactly(2).and_return(project)

      participants = instance.participants(user1)

      expect(participants).to contain_exactly(user2, user3)
    end

    it 'caches participants per user' do
      expect(instance).to receive(:raw_participants).once.and_return([user1])

      participants1 = instance.participants(user1)
      participants2 = instance.participants(user1)

      expect(participants1).to eq(participants2)
    end

    it 'supports attributes returning another Participable' do
      other_model = Class.new do
        include Participable
      end

      other_model.participant(:bar)
      model.participant(:foo)

      instance = model.new
      other = other_model.new

      expect(instance).to receive(:foo).and_return(other)
      expect(other).to receive(:bar).and_return(user2)
      expect(instance).to receive(:project).exactly(2).and_return(project)

      expect(instance.participants(user1)).to contain_exactly(user2)
    end

    context 'when using a Proc as an attribute' do
      it 'calls the supplied Proc' do
        user_arg = nil
        ext_arg = nil

        model.participant ->(user, ext) do
          user_arg = user
          ext_arg = ext
        end

        expect(instance).to receive(:project).exactly(2).and_return(project)

        instance.participants(user1)

        expect(user_arg).to eq(user1)
        expect(ext_arg).to be_an_instance_of(Gitlab::ReferenceExtractor)
      end
    end

    context 'when participable is a personal snippet' do
      let(:model) { PersonalSnippet }
      let(:instance) { model.new(author: user1) }

      before do
        allow(model).to receive(:participant_attrs).and_return([:foo, :bar])
      end

      it 'returns the list of participants without filtering' do
        expect(instance).to receive(:foo).and_return(user1)
        expect(instance).to receive(:bar).and_return(user2)

        participants = instance.participants(user1)

        expect(participants).to contain_exactly(user1, user2)
      end
    end

    context 'when participable is a group level object' do
      it 'returns the list of participants without filtering' do
        model.participant(:foo)
        model.participant(:bar)

        allow(instance).to receive(:project).and_return(nil)

        expect(instance).to receive(:foo).and_return(user2)
        expect(instance).to receive(:bar).and_return(user3)

        participants = instance.participants(user1)

        expect(participants).to contain_exactly(user2, user3)
      end
    end
  end

  describe '#participant?' do
    before do
      allow(model).to receive(:participant_attrs).and_return([:foo, :bar])
    end

    it 'returns whether the user is a participant' do
      allow(instance).to receive(:foo).and_return(user2)
      allow(instance).to receive(:bar).and_return(user3)
      allow(instance).to receive(:project).and_return(project)

      expect(instance.participant?(user1)).to be false
      expect(instance.participant?(user2)).to be true
      expect(instance.participant?(user3)).to be true
    end

    it 'caches the list of raw participants' do
      expect(instance).to receive(:raw_participants).once.and_return([])

      instance.participant?(user1)
      instance.participant?(user1)
    end

    context 'when participable is a personal snippet' do
      let(:model) { PersonalSnippet }
      let(:instance) { model.new(author: user1) }

      it 'returns whether the user is a participant' do
        allow(instance).to receive(:foo).and_return(user1)
        allow(instance).to receive(:bar).and_return(user2)

        expect(instance.participant?(user1)).to be true
        expect(instance.participant?(user2)).to be true
        expect(instance.participant?(user3)).to be false
      end
    end

    context 'when participable is a group level object' do
      it 'returns whether the user is a participant' do
        allow(instance).to receive(:foo).and_return(user1)
        allow(instance).to receive(:bar).and_return(user2)
        allow(instance).to receive(:project).and_return(nil)

        expect(instance.participant?(user1)).to be true
        expect(instance.participant?(user2)).to be true
        expect(instance.participant?(user3)).to be false
      end
    end
  end
end
