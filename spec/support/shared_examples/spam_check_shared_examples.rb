# frozen_string_literal: true

shared_examples 'akismet spam' do
  context 'when request is missing' do
    subject { described_class.new(target: issue, request: nil) }

    it "doesn't check as spam" do
      subject

      expect(issue).not_to be_spam
    end
  end

  context 'when request exists' do
    it 'creates a spam log' do
      expect { subject }
          .to log_spam(title: issue.title, description: issue.description, noteable_type: 'Issue')
    end
  end
end
