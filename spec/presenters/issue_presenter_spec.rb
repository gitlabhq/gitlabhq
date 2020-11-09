# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePresenter do
  include Gitlab::Routing.url_helpers

  let(:user)      { create(:user) }
  let(:group)     { create(:group) }
  let(:project)   { create(:project, group: group) }
  let(:issue)     { create(:issue, project: project) }
  let(:presenter) { described_class.new(issue, current_user: user) }

  before do
    group.add_developer(user)
  end

  describe '#web_url' do
    it 'returns correct path' do
      expect(presenter.web_url).to eq("http://localhost/#{group.name}/#{project.name}/-/issues/#{issue.iid}")
    end
  end

  describe '#subscribed?' do
    subject { presenter.subscribed? }

    it 'returns not subscribed' do
      is_expected.to be(false)
    end

    it 'returns subscribed' do
      create(:subscription, user: user, project: project, subscribable: issue, subscribed: true)

      is_expected.to be(true)
    end
  end

  describe '#issue_path' do
    it 'returns correct path' do
      expect(presenter.issue_path).to eq("/#{group.name}/#{project.name}/-/issues/#{issue.iid}")
    end
  end

  describe '#project_emails_disabled?' do
    subject { presenter.project_emails_disabled? }

    it 'returns false when emails notifications is enabled for project' do
      is_expected.to be(false)
    end

    context 'when emails notifications is disabled for project' do
      before do
        allow(project).to receive(:emails_disabled?).and_return(true)
      end

      it { is_expected.to be(true) }
    end
  end
end
