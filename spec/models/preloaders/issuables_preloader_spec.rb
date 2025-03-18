# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::IssuablesPreloader, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let_it_be(:projects) { create_list(:project, 3, :public, :repository) }
  let_it_be(:issues) { projects.map { |p| create(:issue, project: p) } }
  let_it_be(:associations) { [:namespace] }

  it 'does not produce N+1 queries' do
    first_issue = issues_with_preloaded_data.first
    clean_issues = issues_with_preloaded_data

    expect { access_data(clean_issues) }.to issue_same_number_of_queries_as { access_data([first_issue]) }
  end

  private

  def issues_with_preloaded_data
    i = Issue.where(id: issues.map(&:id))
    described_class.new(i, user, associations).preload_all
    i
  end

  def access_data(issues)
    issues.each { |i| i.project.namespace }
  end
end
