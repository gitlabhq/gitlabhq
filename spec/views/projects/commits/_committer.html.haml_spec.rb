# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commits/_committer.html.haml', feature_category: :source_code_management do
  let(:user) { build(:user, name: 'John Doe', email: 'john@example.com') }
  let(:committer) { build(:user, name: 'Jane Smith', email: 'jane@example.com') }

  let(:commit) do
    build(:commit,
      author: user,
      author_name: user.name,
      author_email: user.email,
      authored_date: 2.days.ago,
      committer: nil,
      committer_name: user.name,
      committer_email: user.email,
      committed_date: 2.days.ago
    )
  end

  before do
    allow(view).to receive_messages(commit_author_link: 'John Doe', time_ago_with_tooltip: '2 days ago')
  end

  context 'when author and committer are the same' do
    before do
      render partial: 'projects/commits/committer', locals: { commit: commit }
    end

    it 'displays only author information' do
      expect(rendered).to have_content('John Doe authored 2 days ago')
      expect(rendered).not_to have_content('committed')
    end
  end

  context 'when author and committer are different' do
    before do
      allow(commit).to receive_messages(different_committer?: true, committer: committer)
      allow(view).to receive_messages(commit_committer_link: 'Jane Smith',
        commit_committer_avatar: '<img src="avatar.jpg">')

      render partial: 'projects/commits/committer', locals: { commit: commit }
    end

    it 'displays both author and committer information' do
      expect(rendered).to have_content('John Doe authored 2 days ago')
      expect(rendered).to have_content('Jane Smith committed 2 days ago')
    end

    it 'includes committer avatar' do
      expect(rendered).to include('avatar.jpg')
    end
  end
end
