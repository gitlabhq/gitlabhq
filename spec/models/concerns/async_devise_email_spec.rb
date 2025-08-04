# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AsyncDeviseEmail, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  describe '#send_devise_notification' do
    let_it_be(:notification) { :confirmation_instructions }
    let_it_be(:args) { [{ to: user.email }] }
    let(:mailer_double) { instance_double(DeviseMailer) }
    let(:mail_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(user).to receive(:devise_mailer).and_return(mailer_double)
      allow(mailer_double).to receive(notification).and_return(mail_double)
    end

    it 'sends the notification asynchronously' do
      expect(mailer_double).to receive(notification).with(user, *args)
      expect(mail_double).to receive(:deliver_later)

      result = user.send(:send_devise_notification, notification, *args)
      expect(result).to be true
    end

    context 'with various notification types' do
      %i[unlock_instructions email_changed reset_password_instructions].each do |notification|
        context "with #{notification} notification" do
          before do
            allow(mailer_double).to receive(notification).and_return(mail_double)
          end

          it 'sends the correct notification' do
            expect(mailer_double).to receive(notification).with(user, *args)
            expect(mail_double).to receive(:deliver_later)

            user.send(:send_devise_notification, notification, *args)
          end
        end
      end
    end

    context 'when the user cannot receive notifications' do
      before do
        allow(user).to receive(:can?).with(:receive_notifications).and_return(false)
        allow(user).to receive(:can?).with(:receive_confirmation_instructions).and_return(false)
      end

      it 'does not send the notification' do
        expect(mailer_double).not_to receive(notification).with(user, *args)
        expect(mail_double).not_to receive(:deliver_later)

        result = user.send(:send_devise_notification, notification, *args)
        expect(result).to be true
      end

      context 'when the user can only receive confirmation instructions' do
        before do
          allow(user).to receive(:can?).with(:receive_confirmation_instructions).and_return(true)
        end

        it 'sends confirmation instructions' do
          expect(mailer_double).to receive(notification).with(user, *args)
          expect(mail_double).to receive(:deliver_later)

          result = user.send(:send_devise_notification, notification, *args)
          expect(result).to be true
        end

        it 'does not send other notifications' do
          expect(mailer_double).not_to receive(:email_changed).with(user, *args)
          expect(mail_double).not_to receive(:deliver_later)

          result = user.send(:send_devise_notification, :email_changed, *args)
          expect(result).to be true
        end
      end

      context 'when the user can receive notifications but not confirmation instructions' do
        before do
          allow(user).to receive(:can?).with(:receive_notifications).and_return(true)
          allow(user).to receive(:can?).with(:receive_confirmation_instructions).and_return(false)
        end

        it 'sends confirmation instructions' do
          expect(mailer_double).to receive(notification).with(user, *args)
          expect(mail_double).to receive(:deliver_later)

          result = user.send(:send_devise_notification, notification, *args)
          expect(result).to be true
        end
      end
    end
  end
end
