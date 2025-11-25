# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Participable, feature_category: :team_planning do
  let(:model) do
    Class.new do
      include Participable
    end
  end

  describe '.participant' do
    it 'adds the participant attributes to the existing list' do
      model.participant(:foo)
      model.participant(:bar)

      expect(model.participant_attrs).to eq([:foo, :bar])
    end
  end

  describe '#participants' do
    it 'returns the list of participants' do
      model.participant(:foo)
      model.participant(:bar)

      user1 = build(:user)
      user2 = build(:user)
      user3 = build(:user)
      project = build(:project, :public)
      instance = model.new

      expect(instance).to receive(:foo).and_return(user2)
      expect(instance).to receive(:bar).and_return(user3)
      expect(instance).to receive(:project).exactly(4).and_return(project)

      participants = instance.participants(user1)

      expect(participants).to include(user2)
      expect(participants).to include(user3)
    end

    it 'caches the list of filtered participants' do
      instance = model.new
      user1 = build(:user)

      expect(instance).to receive(:all_participants_hash).once.and_return({})
      expect(instance).to receive(:filter_by_ability).once

      instance.participants(user1)
      instance.participants(user1)
    end

    it 'supports attributes returning another Participable' do
      other_model = Class.new do
        include Participable
      end

      other_model.participant(:bar)
      model.participant(:foo)

      instance = model.new
      other = other_model.new
      user1 = build(:user)
      user2 = build(:user)
      project = build(:project, :public)

      expect(instance).to receive(:foo).and_return(other)
      expect(other).to receive(:bar).and_return(user2)
      expect(instance).to receive(:project).exactly(4).and_return(project)

      expect(instance.participants(user1)).to eq([user2])
    end

    context 'when using a Proc as an attribute' do
      it 'calls the supplied Proc' do
        user1 = build(:user)
        project = build(:project, :public)

        user_arg = nil
        ext_arg = nil

        model.participant ->(user, ext) do
          user_arg = user
          ext_arg = ext
        end

        instance = model.new

        expect(instance).to receive(:project).exactly(4).and_return(project)

        instance.participants(user1)

        expect(user_arg).to eq(user1)
        expect(ext_arg).to be_an_instance_of(Gitlab::ReferenceExtractor)
      end
    end

    context 'participable is a personal snippet' do
      let(:model) { PersonalSnippet }
      let(:instance) { model.new(author: user1) }

      let(:user1) { build(:user) }
      let(:user2) { build(:user) }
      let(:user3) { build(:user) }

      before do
        allow(model).to receive(:participant_attrs).and_return([:foo, :bar])
      end

      it 'returns the list of participants' do
        expect(instance).to receive(:foo).and_return(user1)
        expect(instance).to receive(:bar).and_return(user2)

        participants = instance.participants(user1)
        expect(participants).to contain_exactly(user1)
      end
    end

    context 'participable is a group level object' do
      it 'returns the list of participants' do
        model.participant(:foo)
        model.participant(:bar)

        user1 = build(:user)
        user2 = build(:user)
        user3 = build(:user)
        group = build(:group, :public)
        instance = model.new

        expect(instance).to receive(:foo).and_return(user2)
        expect(instance).to receive(:bar).and_return(user3)
        expect(instance).to receive(:project).exactly(3).and_return(nil)
        expect(instance).to receive(:namespace).exactly(2).and_return(group)

        participants = instance.participants(user1)

        expect(participants).not_to include(user1)
        expect(participants).to include(user2)
        expect(participants).to include(user3)
      end
    end

    context 'participable is neither a project nor a group level object' do
      it 'returns no participants' do
        model.participant(:foo)

        user = build(:user)
        instance = model.new

        expect(instance).to receive(:foo).and_return(user)
        expect(instance).to receive(:project).exactly(3).and_return(nil)

        participants = instance.participants(user)

        expect(participants).to be_empty
      end
    end
  end

  describe '#participant?' do
    let(:instance) { model.new }

    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:user3) { build(:user) }
    let(:project) { build(:project, :public) }

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
      expect(instance).to receive(:project).exactly(4).and_return(project)

      instance.participant?(user1)
      instance.participant?(user1)
    end

    context 'participable is a personal snippet' do
      let(:model) { PersonalSnippet }
      let(:instance) { model.new(author: user1) }

      it 'returns whether the user is a participant' do
        allow(instance).to receive(:foo).and_return(user1)
        allow(instance).to receive(:bar).and_return(user2)

        expect(instance.participant?(user1)).to be true
        expect(instance.participant?(user2)).to be false
        expect(instance.participant?(user3)).to be false
      end
    end

    context 'when participable is a group level object' do
      let(:group) { create(:group, :private) }

      before do
        # we need users to be created to add them as members to the group
        user1.save!
        user2.save!
        user3.save!

        group.add_reporter(user1)
        group.add_reporter(user2)
      end

      it 'returns whether the user is a participant' do
        allow(instance).to receive(:foo).and_return(user1)
        allow(instance).to receive(:bar).and_return(user3)
        allow(instance).to receive(:project).and_return(nil)
        allow(instance).to receive(:namespace).and_return(group)

        expect(instance.participant?(user1)).to be true # returned by participant attr and a member of group
        expect(instance.participant?(user2)).to be false # returned by participant attr
        expect(instance.participant?(user3)).to be false # not a member of group
      end

      context 'when participable is neither project nor group level object' do
        it 'returns whether the user is a participant' do
          allow(instance).to receive(:foo).and_return(user1)
          allow(instance).to receive(:project).and_return(nil)

          # user1 is returned by participant attr and is a member of group,
          # but participable model is neither a group or project object
          expect(instance.participant?(user1)).to be false
        end
      end
    end
  end
end
