require 'spec_helper'

describe Issue, "Mentionable" do
  describe :mentioned_users do
    let!(:user) { create(:user, username: 'stranger') }
    let!(:user2) { create(:user, username: 'john') }
    let!(:issue) { create(:issue, description: '@stranger mentioned') }

    subject { issue.mentioned_users }

    it { should include(user) }
    it { should_not include(user2) }
  end
end
