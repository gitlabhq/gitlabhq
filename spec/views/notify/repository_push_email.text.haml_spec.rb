# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/repository_push_email.text.haml', feature_category: :source_code_management do
  let(:message) do
    instance_double(
      Gitlab::Email::Message::RepositoryPush, compare: double, commits: [commit], diffs: []
    ).as_null_object
  end

  let(:commit) do
    instance_double(
      Gitlab::Git::Commit, safe_message: commit_message, committed_date: Time.zone.today
    ).as_null_object
  end

  let(:commit_message) { "special char'acters" }

  before do
    assign(:message, message)
  end

  it 'does not escape special characters for plain text emails' do
    render

    expect(rendered).to have_content(commit_message)
  end
end
