require 'spec_helper'

describe UserObserver do
  subject { UserObserver.instance }

  it 'calls #after_create when new users are created' do
    new_user = build(:user)
    subject.should_receive(:after_create).with(new_user)
    new_user.save
  end

  context 'when a new user is created' do
    it 'sends an email' do
      Notify.should_receive(:new_user_email)
      create(:user)
    end

    it 'no email for external' do
      Notify.should_not_receive(:new_user_email)
      create(:user, extern_uid: '32442eEfsafada')
    end

    it 'trigger logger' do
      user = double(:user, id: 42, password: 'P@ssword!', name: 'John', email: 'u@mail.local', extern_uid?: false)
      Gitlab::AppLogger.should_receive(:info)
      create(:user)
    end
  end
end
