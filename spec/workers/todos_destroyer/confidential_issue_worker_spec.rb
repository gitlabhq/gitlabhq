# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosDestroyer::ConfidentialIssueWorker, feature_category: :team_planning do
  let(:service) { double }

  it "calls the Todos::Destroy::ConfidentialIssueService with issue_id parameter" do
    expect(::Todos::Destroy::ConfidentialIssueService).to receive(:new).with(issue_id: 100, project_id: nil).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(100)
  end

  it "calls the Todos::Destroy::ConfidentialIssueService with project_id parameter" do
    expect(::Todos::Destroy::ConfidentialIssueService).to receive(:new).with(issue_id: nil, project_id: 100).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(nil, 100)
  end
end
