require 'spec_helper'

describe UserObserver do
  before(:each) { enable_observers }
  after(:each) {disable_observers}
  subject { UserObserver.instance }
  before { subject.stub(notification: double('NotificationService').as_null_object) }

  it 'calls #after_create when new users are created' do
    new_user = build(:user)
    subject.should_receive(:after_create).with(new_user)
    new_user.save
  end

  context 'when a new user is created' do
    it 'sends an email' do
      subject.should_receive(:notification)
      create(:user)
    end

    it 'trigger logger' do
      user = double(:user, id: 42, password: 'P@ssword!', name: 'John', email: 'u@mail.local', extern_uid?: false)
      Gitlab::AppLogger.should_receive(:info)
      create(:user)
    end
  end
end
