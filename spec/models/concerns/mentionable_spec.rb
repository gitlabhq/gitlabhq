require 'spec_helper'

describe Issue, "Mentionable" do
  describe :mentioned_users do
    let!(:user) { create(:user, username: 'stranger') }
    let!(:user2) { create(:user, username: 'john') }
    let!(:issue) { create(:issue, description: '@stranger mentioned') }

    subject { issue.mentioned_users }

    it { is_expected.to include(user) }
    it { is_expected.not_to include(user2) }
  end
end
