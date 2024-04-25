# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueMove do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, developers: user) }
  let_it_be(:other_project) { create(:project, developers: user) }
  let_it_be(:old_issue, reload: true) { create(:issue, project: project) }

  let(:new_issue) { Issues::MoveService.new(container: project, current_user: user).execute(old_issue, other_project) }
  let(:attachment) { subject[:attachments].first }

  subject { described_class.new(new_issue).present(old_issue) }

  it { is_expected.to be_a(Hash) }

  it 'shows the new issue' do
    expect(subject[:response_type]).to be(:in_channel)
    expect(subject).to have_key(:attachments)
    expect(attachment[:title]).to start_with(new_issue.title)
    expect(attachment[:title_link]).to include(other_project.full_path)
  end

  it 'mentions the old issue and the new issue in the pretext' do
    expect(attachment[:pretext]).to include(project.full_path)
    expect(attachment[:pretext]).to include(other_project.full_path)
  end
end
