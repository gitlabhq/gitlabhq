# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemPresenter, feature_category: :portfolio_management do
  let(:work_item) { build_stubbed(:work_item) }

  it 'presents a work item and uses methods defined in IssuePresenter' do
    user = build_stubbed(:user)
    presenter = work_item.present(current_user: user)

    expect(presenter.issue_path).to eq(presenter.web_path)
  end
end
