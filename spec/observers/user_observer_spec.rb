require 'spec_helper'

describe UserObserver do
  subject { UserObserver.instance }

  it 'calls #after_create when new users are created' do
    new_user = build(:user)
    subject.should_receive(:after_create).with(new_user)

    User.observers.enable :user_observer do
      new_user.save
    end
  end

  context 'when a new user is created' do
    let(:user) { double(:user, id: 42,
                        password: 'P@ssword!',
                        name: 'John',
                        email: 'u@mail.local',
                        username: 'root',
                        create_namespace: true) }
    let(:notification) { double :notification }

    it 'sends an email' do
      notification.should_receive(:deliver)
      Notify.should_receive(:new_user_email).with(user.id, user.password).and_return(notification)

      subject.after_create(user)
    end

    it 'trigger logger' do
      Gitlab::AppLogger.should_receive(:info)
      subject.after_create(user)
    end
  end
end
