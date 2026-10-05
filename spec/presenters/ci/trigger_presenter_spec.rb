# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerPresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }

  let(:trigger) { build_stubbed(:ci_trigger, token: '123456789abcd', project: project) }

  subject do
    described_class.new(trigger, current_user: user)
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
    let(:trigger) { build_stubbed(:ci_trigger, token: '123456789abcd', project: project, owner: user) }

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
