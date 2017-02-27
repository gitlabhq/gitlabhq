require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'csv export email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:empty_project) }
    subject { Notify.issues_csv_email(user, empty_project, "dummy content", 3) }

    it 'attachment has csv mime type' do
      attachment = subject.attachments.first
      expect(attachment.mime_type).to eq 'text/csv'
    end

    it 'mentions number of issues and project name' do
      expect(subject).to have_content '3'
      expect(subject).to have_content empty_project.name
    end
  end
end
