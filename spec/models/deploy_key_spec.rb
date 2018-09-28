require 'spec_helper'

describe DeployKey, :mailer do
  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:projects) }
  end

  describe 'notification' do
    let(:user) { create(:user) }

    it 'does not send a notification' do
      perform_enqueued_jobs do
        create(:deploy_key, user: user)
      end

      should_not_email(user)
    end
  end

  describe '#user' do
    let(:deploy_key) { create(:deploy_key) }
    let(:user) { create(:user) }

    context 'when user is set' do
      before do
        deploy_key.user = user
      end

      it 'returns the user' do
        expect(deploy_key.user).to be(user)
      end
    end

    context 'when user is not set' do
      it 'returns the ghost user' do
        expect(deploy_key.user).to eq(User.ghost)
      end
    end
  end
end
