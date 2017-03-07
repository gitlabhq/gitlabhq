require 'spec_helper'
require 'email_spec'

describe Notify do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'csv export email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:empty_project, path: 'myproject') }
    let(:truncated) { false }
    subject { Notify.issues_csv_email(user, empty_project, "dummy content", 3, truncated) }
    let(:attachment) { subject.attachments.first }

    it 'attachment has csv mime type' do
      expect(attachment.mime_type).to eq 'text/csv'
    end

    it 'generates a useful filename' do
      expect(attachment.filename).to include(Date.today.year.to_s)
      expect(attachment.filename).to include('issues')
      expect(attachment.filename).to include('myproject')
      expect(attachment.filename).to end_with('.csv')
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
