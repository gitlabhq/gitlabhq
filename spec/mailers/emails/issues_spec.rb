require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'csv export email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:empty_project) }
    let(:truncated) { false }
    subject { Notify.issues_csv_email(user, empty_project, "dummy content", 3, truncated) }

    it 'attachment has csv mime type' do
      attachment = subject.attachments.first
      expect(attachment.mime_type).to eq 'text/csv'
    end

    it 'mentions number of issues and project name' do
      expect(subject).to have_content '3'
      expect(subject).to have_content empty_project.name
    end

    it "doesn't need to mention truncation by default" do
      expect(subject).not_to have_content 'truncated'
    end

    context 'when truncated' do
      let(:truncated) { true }

      it 'mentions that the csv has been truncated' do
        expect(subject).to have_content 'truncated'
      end
    end
  end
end
