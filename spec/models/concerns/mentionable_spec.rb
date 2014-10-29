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
