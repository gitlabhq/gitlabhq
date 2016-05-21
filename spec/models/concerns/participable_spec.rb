require 'spec_helper'

describe Participable, models: true do
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

      allow(instance).to receive(:foo).and_return(user2)
      allow(instance).to receive(:bar).and_return(user3)
      allow(instance).to receive(:project).and_return(project)

      expect(instance.participants(user1)).to eq([user2, user3])
    end

    context 'when using a Proc as an attribute' do
      it 'calls the supplied Proc' do
        user1 = build(:user)
        user2 = build(:user)
        project = build(:project, :public)

        model.participant proc { user2 }

        instance = model.new

        allow(instance).to receive(:project).and_return(project)
        expect(instance.participants(user1)).to eq([user2])
      end

      it 'passes the current user to the Proc' do
        user1 = build(:user)
        project = build(:project, :public)

        model.participant proc { |user| user }

        instance = model.new

        allow(instance).to receive(:project).and_return(project)
        expect(instance.participants(user1)).to eq([user1])
      end
    end
  end
end
