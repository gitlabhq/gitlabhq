# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueSearch do
  let(:project) { create(:project) }
  let(:message) { subject[:text] }

  before do
    create_list(:issue, 2, project: project)
  end

  subject { described_class.new(project.issues).present }

  it 'formats the message correct' do
    is_expected.to have_key(:text)
    is_expected.to have_key(:status)
    is_expected.to have_key(:response_type)
    is_expected.to have_key(:attachments)
  end

  it 'shows a list of results' do
    expect(subject[:response_type]).to be(:ephemeral)

    expect(message).to start_with("Here are the 2 issues I found")
  end
end
