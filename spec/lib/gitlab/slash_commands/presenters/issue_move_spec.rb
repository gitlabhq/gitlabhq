# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueMove, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, developers: user) }
  let_it_be(:other_project) { create(:project, developers: user) }
  let_it_be(:old_issue, reload: true) { create(:issue, project: project) }

  let(:attachment) { subject[:attachments].first }
  let(:new_issue) do
    ::WorkItems::DataSync::MoveService.new(
      work_item: old_issue, current_user: user, target_namespace: other_project.project_namespace
    ).execute[:work_item]
  end

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
