# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Result do
  let_it_be(:actor) { create(:user) }

  subject(:result) { described_class.new(actor, nil, nil, []) }

  context 'when actor is User' do
    let_it_be(:actor) { create(:user) }

    it 'returns auth_user' do
      expect(result.auth_user).to eq(actor)
    end

    it 'does not return deploy token' do
      expect(result.deploy_token).to be_nil
    end
  end

  context 'when actor is Deploy token' do
    let_it_be(:actor) { create(:deploy_token) }

    it 'returns deploy token' do
      expect(result.deploy_token).to eq(actor)
    end

    it 'does not return auth_user' do
      expect(result.auth_user).to be_nil
    end
  end

  describe '#authentication_abilities_include?' do
    context 'when authentication abilities are empty' do
      it 'returns false' do
        expect(result.authentication_abilities_include?(:read_code)).to be_falsey
      end
    end

    context 'when authentication abilities are not empty' do
      subject(:result) { described_class.new(actor, nil, nil, [:push_code]) }

      it 'returns false when ability is not allowed' do
        expect(result.authentication_abilities_include?(:read_code)).to be_falsey
      end

      it 'returns true when ability is allowed' do
        expect(result.authentication_abilities_include?(:push_code)).to be_truthy
      end
    end
  end

  describe '#personal_access_token' do
    context 'when a token is not present' do
      it 'returns nil' do
        expect(result.personal_access_token).to be_nil
      end
    end

    context 'when a token is present' do
      let(:pat) { build(:personal_access_token) }

      subject(:result) { described_class.new(actor, nil, nil, [], personal_access_token: pat) }

      it 'returns the token' do
        expect(result.personal_access_token).to eq(pat)
      end
    end
  end

  describe '#can_perform_action_on_project?' do
    let(:project) { double }

    it 'returns if actor can do perform given action on given project' do
      expect(Ability).to receive(:allowed?).with(actor, :push_code, project).and_return(true)
      expect(result.can_perform_action_on_project?(:push_code, project)).to be_truthy
    end

    it 'returns if actor cannot do perform given action on given project' do
      expect(Ability).to receive(:allowed?).with(actor, :push_code, project).and_return(false)
      expect(result.can_perform_action_on_project?(:push_code, project)).to be_falsey
    end
  end

  describe '#gitlab_shell?' do
    it 'returns true when type is :gitlab_shell' do
      result = described_class.new(actor, nil, :gitlab_shell, nil)

      expect(result.gitlab_shell?).to be true
    end

    it 'returns false for other types' do
      result = described_class.new(nil, nil, :ci, nil)

      expect(result.gitlab_shell?).to be false
    end
  end

  describe '#can?' do
    it 'returns if actor can do perform given action on given project' do
      expect(actor).to receive(:can?).with(:push_code).and_return(true)
      expect(result.can?(:push_code)).to be_truthy
    end

    it 'returns if actor cannot do perform given action on given project' do
      expect(actor).to receive(:can?).with(:push_code).and_return(false)
      expect(result.can?(:push_code)).to be_falsey
    end
  end
end
