require 'spec_helper'

describe EmailObserver do
  let(:email)      { create(:email) }

  before { subject.stub(notification: double('NotificationService').as_null_object) }

  subject { EmailObserver.instance }

  describe '#after_create' do
    it 'trigger notification to send emails' do
      subject.should_receive(:notification)

      subject.after_create(email)
    end
  end
end
