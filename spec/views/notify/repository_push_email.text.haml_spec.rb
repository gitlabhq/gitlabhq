# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/repository_push_email.text.haml', feature_category: :source_code_management do
  let(:message) do
    instance_double(
      Gitlab::Email::Message::RepositoryPush,
      compare: double,
      commits: [commit],
      changed_files: changed_files,
      diffs: []
    ).as_null_object
  end

  let(:commit) do
    instance_double(
      Gitlab::Git::Commit, safe_message: commit_message, committed_date: Time.zone.today
    ).as_null_object
  end

  let(:commit_message) { 'message' }
  let(:changed_files) do
    [
      Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'a.txt', old_mode: '100644', new_mode: '100644'),
      Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'b.txt', old_mode: '100644', new_mode: '100644')
    ]
  end

  before do
    assign(:message, message)
  end

  it 'renders changed files' do
    render

    expect(rendered).to have_content('a.txt').and have_content('b.txt')
  end

  context 'when commit message includes special characters' do
    let(:commit_message) { "special char'acters" }

    it 'does not escape special characters for plain text emails' do
      render

      expect(rendered).to have_content(commit_message)
    end
  end
end
