# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_project_issuable_url_helpers'

RSpec.describe RuboCop::Cop::Gitlab::AvoidProjectIssuableUrlHelpers, feature_category: :team_planning do
  shared_examples 'raises rubocop offense' do |method|
    it "registers an offense for #{method}" do
      expect_offense(<<~RUBY)
      #{method}(project, issue)
      #{'^' * method.length} Avoid using `#{method}`. [...]
      RUBY
    end
  end

  it_behaves_like 'raises rubocop offense', 'project_issue_url'
  it_behaves_like 'raises rubocop offense', 'project_issue_path'
  it_behaves_like 'raises rubocop offense', 'project_work_item_url'
  it_behaves_like 'raises rubocop offense', 'project_work_item_path'

  it 'registers an offense for safe navigation (&.) operator form' do
    expect_offense(<<~RUBY)
      foo&.project_issue_url(project, issue)
           ^^^^^^^^^^^^^^^^^ Avoid using `project_issue_url`. [...]
    RUBY
  end

  it 'registers an offense when called with keyword arguments' do
    expect_offense(<<~RUBY)
      project_issue_url(project, issue, only_path: true)
      ^^^^^^^^^^^^^^^^^ Avoid using `project_issue_url`. [...]
    RUBY
  end

  it 'does not register an offense for Gitlab::UrlBuilder.build' do
    expect_no_offenses(<<~RUBY)
      Gitlab::UrlBuilder.build(issue)
    RUBY
  end

  it 'does not register an offense for unrelated URL helpers' do
    expect_no_offenses(<<~RUBY)
      project_issues_url(project)
    RUBY
  end
end
