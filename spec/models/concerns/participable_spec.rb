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

    it 'supports inserting attributes at a specific location' do
      model.participant(:foo)
      model.participant(:bar, index: 0)

      expect(model.participant_attrs).to eq([:bar, :foo])
    end
  end

  describe '#participants' do
    it 'returns the list of participants' do
      model.participant(:foo)
      model.participant(:bar)

      user1 = build(:user)
      user2 = build(:user)
      user3 = build(:user)
      project = build(:project)
      instance = model.new

      expect(instance).to receive(:foo).and_return(user2)
      expect(instance).to receive(:bar).and_return(user3)
      expect(instance).to receive(:project).twice.and_return(project)

      expect(user2).to receive(:can?).
        with(:read_project, project).
        and_return(true)

      expect(user3).to receive(:can?).
        with(:read_project, project).
        and_return(true)

      expect(instance.participants(user1)).to eq([user2, user3])
    end

    context 'when using a Proc as an attribute' do
      it 'calls the supplied Proc' do
        user1 = build(:user)
        user2 = build(:user)

        model.participant proc { user2 }

        expect(model.new.participants(user1)).to eq([user2])
      end

      it 'passes the current user to the Proc' do
        user1 = build(:user)

        model.participant proc { |user| user }

        expect(model.new.participants(user1)).to eq([user1])
      end
    end
  end
end
