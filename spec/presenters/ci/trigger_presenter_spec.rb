require 'spec_helper'

describe Ci::TriggerPresenter do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  set(:trigger) do
    create(:ci_trigger, token: '123456789abcd', project: project)
  end

  subject do
    described_class.new(trigger, current_user: user)
  end

  before do
    project.add_maintainer(user)
  end

  context 'when user is not a trigger owner' do
    describe '#token' do
      it 'exposes only short token' do
        expect(subject.token).not_to eq trigger.token
        expect(subject.token).to eq '1234'
      end
    end

    describe '#has_token_exposed?' do
      it 'does not have token exposed' do
        expect(subject).not_to have_token_exposed
      end
    end
  end

  context 'when user is a trigger owner and builds admin' do
    before do
      trigger.update(owner: user)
    end

    describe '#token' do
      it 'exposes full token' do
        expect(subject.token).to eq trigger.token
      end
    end

    describe '#has_token_exposed?' do
      it 'has token exposed' do
        expect(subject).to have_token_exposed
      end
    end
  end
end
