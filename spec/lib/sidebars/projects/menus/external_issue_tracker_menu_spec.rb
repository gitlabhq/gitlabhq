# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ExternalIssueTrackerMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:jira_issues_integration_active) { false }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, jira_issues_integration: jira_issues_integration_active) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  describe '#render?' do
    before do
      expect(subject).to receive(:external_issue_tracker).and_return(external_issue_tracker).at_least(1)
    end

    context 'when active external issue tracker' do
      let(:external_issue_tracker) { build(:custom_issue_tracker_integration, project: project) }

      context 'is present' do
        it 'returns true' do
          expect(subject.render?).to be_truthy
        end
      end

      context 'is not present' do
        let(:external_issue_tracker) { nil }

        it 'returns false' do
          expect(subject.render?).to be_falsey
        end
      end
    end
  end
end
