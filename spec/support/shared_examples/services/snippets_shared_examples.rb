# frozen_string_literal: true

RSpec.shared_examples 'snippets spam check is performed' do
  shared_examples 'marked as spam' do
    it 'marks a snippet as spam' do
      expect(snippet).to be_spam
    end

    it 'invalidates the snippet' do
      expect(snippet).to be_invalid
    end

    it 'creates a new spam_log' do
      expect { snippet }
        .to have_spam_log(title: snippet.title, noteable_type: snippet.class.name)
    end

    it 'assigns a spam_log to an issue' do
      expect(snippet.spam_log).to eq(SpamLog.last)
    end
  end

  let(:extra_opts) do
    { visibility_level: Gitlab::VisibilityLevel::PUBLIC, request: double(:request, env: {}) }
  end

  before do
    expect_next_instance_of(Spam::AkismetService) do |akismet_service|
      expect(akismet_service).to receive_messages(spam?: true)
    end
  end

  [true, false, nil].each do |allow_possible_spam|
    context "when allow_possible_spam flag is #{allow_possible_spam.inspect}" do
      before do
        stub_feature_flags(allow_possible_spam: allow_possible_spam) unless allow_possible_spam.nil?
      end

      it_behaves_like 'marked as spam'
    end
  end
end

shared_examples 'invalid params error response' do
  before do
    allow_next_instance_of(described_class) do |service|
      allow(service).to receive(:valid_params?).and_return false
    end
  end

  it 'responds to errors appropriately' do
    response = subject

    aggregate_failures do
      expect(response).to be_error
      expect(response.http_status).to eq 422
    end
  end
end
