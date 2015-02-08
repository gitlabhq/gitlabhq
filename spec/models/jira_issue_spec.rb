require 'spec_helper'

describe JiraIssue do
  let(:project) { create(:project) }
  subject { JiraIssue.new('JIRA-123', project) }

  its(:id) { should eq('JIRA-123') }
  its(:iid) { should eq('JIRA-123') }
  its(:to_s) { should eq('JIRA-123') }

  describe :== do
    specify { subject.should eq(JiraIssue.new('JIRA-123', project)) }
    specify { subject.should_not eq(JiraIssue.new('JIRA-124', project)) }

    it 'only compares with JiraIssues' do
      subject.should_not eq('JIRA-123')
    end
  end
end
