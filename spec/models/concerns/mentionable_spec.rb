require 'spec_helper'

describe Issue, "Mentionable" do
  describe :mentioned_users do
    let!(:user) { create(:user, username: 'john') }
    context 'mentioning an user with the username starting with a letter' do
      let!(:user_mentioned) { create(:user, username: 'stranger') }
      let!(:issue) { create(:issue, description: '@stranger mentioned') }

      subject { issue.mentioned_users }

      it { is_expected.to include(user_mentioned) }
      it { is_expected.not_to include(user) }
    end

    context 'mentioning an user with the username starting with a number' do
      let!(:user_mentioned) { create(:user, username: '123stranger') }
      let!(:issue) { create(:issue, description: '@123stranger mentioned') }

      subject { issue.mentioned_users }

      it { is_expected.to include(user_mentioned) }
      it { is_expected.not_to include(user) }
    end
  end
end
