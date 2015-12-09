require 'spec_helper'

describe CreateSnippetService, services: true do
  before do
    @user = create :user
    @admin = create :user, admin: true
    @opts = {
      title: 'Test snippet',
      file_name: 'snippet.rb',
      content: 'puts "hello world"',
      visibility_level: Gitlab::VisibilityLevel::PRIVATE
    }
  end

  context 'When public visibility is restricted' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'non-admins should not be able to create a public snippet' do
      snippet = create_snippet(nil, @user, @opts)
      expect(snippet.errors.messages).to have_key(:visibility_level)
      expect(snippet.errors.messages[:visibility_level].first).to(
        match('Public visibility has been restricted')
      )
    end

    it 'admins should be able to create a public snippet' do
      snippet = create_snippet(nil, @admin, @opts)
      expect(snippet.errors.any?).to be_falsey
      expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end
  end

  def create_snippet(project, user, opts)
    CreateSnippetService.new(project, user, opts).execute
  end
end
