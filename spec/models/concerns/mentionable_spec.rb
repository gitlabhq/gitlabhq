require 'spec_helper'

describe Mentionable do
  include Mentionable

  describe :references do
    let(:project) { create(:project) }

    it 'excludes JIRA references' do
      project.stub(jira_tracker?: true)
      references(project, 'JIRA-123').should be_empty
    end
  end
end

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
