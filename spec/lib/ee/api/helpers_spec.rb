require 'spec_helper'

describe EE::API::Helpers do
  let(:helper) { Class.new { include API::Helpers }.new }

  before do
    allow(helper).to receive(:env).and_return({})
    allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
  end

  describe '#current_user' do
    let(:user) { build(:user, id: 42) }

    before do
      allow(helper).to receive(:sudo!)
    end

    it 'handles sticking when a user could be found' do
      allow(helper).to receive(:initial_current_user).and_return(user)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        to receive(:stick_or_unstick).with({}, :user, 42)

      helper.current_user
    end

    it 'does not handle sticking if no user could be found' do
      allow(helper).to receive(:initial_current_user).and_return(nil)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        not_to receive(:stick_or_unstick)

      helper.current_user
    end

    it 'returns the user if one could be found' do
      allow(helper).to receive(:initial_current_user).and_return(user)

      expect(helper.current_user).to eq(user)
    end
  end
end
