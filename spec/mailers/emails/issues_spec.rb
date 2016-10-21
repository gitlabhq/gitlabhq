require 'spec_helper'
require 'email_spec'
require 'mailers/shared/notify'

describe Notify do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe 'csv export email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:empty_project) }
    subject { Notify.issues_csv_email(user, project, "dummy content") }

    it 'attachment has csv mime type' do
      attachment = subject.attachments.first
      expect(attachment.mime_type).to eq 'text/csv'
    end
  end
end
