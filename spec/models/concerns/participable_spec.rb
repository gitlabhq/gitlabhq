require 'spec_helper'

describe Participable do
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
      expect(instance).to receive(:project).twice.and_return(project)

      participants = instance.participants(user1)

      expect(participants).to include(user2)
      expect(participants).to include(user3)
    end

    it 'caches the raw list of participants' do
      instance = model.new
      user1 = build(:user)

      expect(instance).to receive(:raw_participants).once

      instance.participants(user1)
      instance.participants(user1)
    end

    it 'supports attributes returning another Participable' do
      other_model = Class.new { include Participable }

      other_model.participant(:bar)
      model.participant(:foo)

      instance = model.new
      other = other_model.new
      user1 = build(:user)
      user2 = build(:user)
      project = build(:project, :public)

      expect(instance).to receive(:foo).and_return(other)
      expect(other).to receive(:bar).and_return(user2)
      expect(instance).to receive(:project).twice.and_return(project)

      expect(instance.participants(user1)).to eq([user2])
    end

    context 'when using a Proc as an attribute' do
      it 'calls the supplied Proc' do
        user1 = build(:user)
        project = build(:project, :public)

        user_arg = nil
        ext_arg = nil

        model.participant -> (user, ext) do
          user_arg = user
          ext_arg = ext
        end

        instance = model.new

        expect(instance).to receive(:project).twice.and_return(project)

        instance.participants(user1)

        expect(user_arg).to eq(user1)
        expect(ext_arg).to be_an_instance_of(Gitlab::ReferenceExtractor)
      end
    end
  end
end
