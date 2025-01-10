# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemPresenter, feature_category: :portfolio_management do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:original_work_item) { build_stubbed(:work_item, project: project) }
  let(:target_work_item) { build_stubbed(:work_item, project: project) }
  let(:target_work_item_url) { Gitlab::UrlBuilder.build(target_work_item) }

  subject(:presenter) { described_class.new(original_work_item, current_user: user) }

  it 'presents a work item and uses methods defined in IssuePresenter' do
    expect(presenter.issue_path).to eq(presenter.web_path)
  end

  shared_examples 'returns target work item url based on permissions' do
    context 'when anonymous' do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end

    context 'with signed in user' do
      before do
        stub_member_access_level(project, access_level => user) if access_level
      end

      context 'when user has no role in project' do
        let(:access_level) { nil }

        it { is_expected.to be_nil }
      end

      context 'when user has guest role in project' do
        let(:access_level) { :guest }

        it { is_expected.to eq(target_work_item_url) }
      end

      context 'when user has reporter role in project' do
        let(:access_level) { :reporter }

        it { is_expected.to eq(target_work_item_url) }
      end

      context 'when user has developer role in project' do
        let(:access_level) { :developer }

        it { is_expected.to eq(target_work_item_url) }
      end
    end
  end

  describe '#duplicated_to_work_item_url' do
    subject { presenter.duplicated_to_work_item_url }

    it { is_expected.to be_nil }

    it_behaves_like 'returns target work item url based on permissions' do
      let(:original_work_item) { build_stubbed(:work_item, project: project, duplicated_to: target_work_item) }
    end
  end

  describe '#moved_to_work_item_url' do
    subject { presenter.moved_to_work_item_url }

    it { is_expected.to be_nil }

    it_behaves_like 'returns target work item url based on permissions' do
      # Create original work item in other project
      let(:original_work_item) { build_stubbed(:work_item, moved_to: target_work_item) }
    end
  end
end
