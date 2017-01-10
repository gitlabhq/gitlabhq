require 'spec_helper'

describe Gitlab::ChatCommands::Presenters::ListIssues do
  let(:project) { create(:empty_project) }
  let(:message) { subject[:text] }
  let(:issue) { project.issues.first }

  before { create_list(:issue, 2, project: project) }

  subject { described_class.new(project.issues).present }

  it do
    is_expected.to have_key(:text)
    is_expected.to have_key(:status)
    is_expected.to have_key(:response_type)
    is_expected.to have_key(:attachments)
  end

  it 'shows a list of results' do
    expect(subject[:response_type]).to be(:ephemeral)

    expect(message).to start_with("Here are the issues I found")
  end
end
