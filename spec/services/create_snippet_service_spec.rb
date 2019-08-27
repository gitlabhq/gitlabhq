# frozen_string_literal: true

require 'spec_helper'

describe CreateSnippetService do
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

    it 'non-admins are not able to create a public snippet' do
      snippet = create_snippet(nil, @user, @opts)
      expect(snippet.errors.messages).to have_key(:visibility_level)
      expect(snippet.errors.messages[:visibility_level].first).to(
        match('has been restricted')
      )
    end

    it 'admins are able to create a public snippet' do
      snippet = create_snippet(nil, @admin, @opts)
      expect(snippet.errors.any?).to be_falsey
      expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    describe "when visibility level is passed as a string" do
      before do
        @opts[:visibility] = 'internal'
        @opts.delete(:visibility_level)
      end

      it "assigns the correct visibility level" do
        snippet = create_snippet(nil, @user, @opts)
        expect(snippet.errors.any?).to be_falsey
        expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end
  end

  describe 'usage counter' do
    let(:counter) { Gitlab::UsageDataCounters::SnippetCounter }

    it 'increments count' do
      expect do
        create_snippet(nil, @admin, @opts)
      end.to change { counter.read(:create) }.by 1
    end

    it 'does not increment count if create fails' do
      expect do
        create_snippet(nil, @admin, {})
      end.not_to change { counter.read(:create) }
    end
  end

  def create_snippet(project, user, opts)
    CreateSnippetService.new(project, user, opts).execute
  end
end
