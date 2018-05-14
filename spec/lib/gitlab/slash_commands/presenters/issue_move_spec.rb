require 'spec_helper'

describe Gitlab::SlashCommands::Presenters::IssueMove do
  set(:admin) { create(:admin) }
  set(:project) { create(:project) }
  set(:other_project) { create(:project) }
  set(:old_issue) { create(:issue, project: project) }
  set(:new_issue) { Issues::MoveService.new(project, admin).execute(old_issue, other_project) }
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
