# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Result do
  subject { described_class.new(actor, nil, nil, []) }

  context 'when actor is User' do
    let(:actor) { create(:user) }

    it 'returns auth_user' do
      expect(subject.auth_user).to eq(actor)
    end

    it 'does not return deploy token' do
      expect(subject.deploy_token).to be_nil
    end
  end

  context 'when actor is Deploy token' do
    let(:actor) { create(:deploy_token) }

    it 'returns deploy token' do
      expect(subject.deploy_token).to eq(actor)
    end

    it 'does not return auth_user' do
      expect(subject.auth_user).to be_nil
    end
  end
end
