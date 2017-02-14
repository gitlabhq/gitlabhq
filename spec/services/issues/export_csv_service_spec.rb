require 'spec_helper'

describe Issues::ExportCsvService, services: true do
  let(:project) { create(:project) }
  let!(:issues) { create_list(:issue, 2, project: project) }
  let(:subject) { described_class.new(Issue.all) }

  it 'renders csv to string' do
    expect(subject.render).to be_a String
  end

  describe '#email' do
      let(:user) { double(notification_email: 'notification@example.com') }

      it 'emails csv' do
        expect{ subject.email(user, project) }.to change(ActionMailer::Base.deliveries, :count)
      end
  end

  it 'renders csv to temporary file'
  it 'includes relevent details (move from feature spec)'
end
