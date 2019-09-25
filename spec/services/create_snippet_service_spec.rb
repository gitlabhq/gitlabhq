# frozen_string_literal: true

require 'spec_helper'

describe CreateSnippetService do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:opts) { base_opts.merge(extra_opts) }
  let(:base_opts) do
    {
      title: 'Test snippet',
      file_name: 'snippet.rb',
      content: 'puts "hello world"',
      visibility_level: Gitlab::VisibilityLevel::PRIVATE
    }
  end
  let(:extra_opts) { {} }

  context 'When public visibility is restricted' do
    let(:extra_opts) { { visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'non-admins are not able to create a public snippet' do
      snippet = create_snippet(nil, user, opts)
      expect(snippet.errors.messages).to have_key(:visibility_level)
      expect(snippet.errors.messages[:visibility_level].first).to(
        match('has been restricted')
      )
    end

    it 'admins are able to create a public snippet' do
      snippet = create_snippet(nil, admin, opts)
      expect(snippet.errors.any?).to be_falsey
      expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    describe "when visibility level is passed as a string" do
      let(:extra_opts) { { visibility: 'internal' } }

      before do
        base_opts.delete(:visibility_level)
      end

      it "assigns the correct visibility level" do
        snippet = create_snippet(nil, user, opts)
        expect(snippet.errors.any?).to be_falsey
        expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end
  end

  context 'checking spam' do
    shared_examples 'marked as spam' do
      let(:snippet) { create_snippet(nil, admin, opts) }

      it 'marks a snippet as a spam ' do
        expect(snippet).to be_spam
      end

      it 'invalidates the snippet' do
        expect(snippet).to be_invalid
      end

      it 'creates a new spam_log' do
        expect { snippet }
          .to log_spam(title: snippet.title, noteable_type: 'PersonalSnippet')
      end

      it 'assigns a spam_log to an issue' do
        expect(snippet.spam_log).to eq(SpamLog.last)
      end
    end

    let(:extra_opts) do
      { visibility_level: Gitlab::VisibilityLevel::PUBLIC, request: double(:request, env: {}) }
    end

    before do
      expect_next_instance_of(AkismetService) do |akismet_service|
        expect(akismet_service).to receive_messages(spam?: true)
      end
    end

    [true, false, nil].each do |allow_possible_spam|
      context "when recaptcha_disabled flag is #{allow_possible_spam.inspect}" do
        before do
          stub_feature_flags(allow_possible_spam: allow_possible_spam) unless allow_possible_spam.nil?
        end

        it_behaves_like 'marked as spam'
      end
    end
  end

  describe 'usage counter' do
    let(:counter) { Gitlab::UsageDataCounters::SnippetCounter }

    it 'increments count' do
      expect do
        create_snippet(nil, admin, opts)
      end.to change { counter.read(:create) }.by 1
    end

    it 'does not increment count if create fails' do
      expect do
        create_snippet(nil, admin, {})
      end.not_to change { counter.read(:create) }
    end
  end

  def create_snippet(project, user, opts)
    CreateSnippetService.new(project, user, opts).execute
  end
end
