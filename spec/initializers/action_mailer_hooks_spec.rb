# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionMailer hooks' do
  describe 'smime signature interceptor' do
    before do
      class_spy(ActionMailer::Base).as_stubbed_const

      # rspec-rails calls ActionMailer::Base.deliveries.clear after every test
      # https://github.com/rspec/rspec-rails/commit/71c12388e2bad78aaeea6443a393ede78341a7a3
      allow(ActionMailer::Base).to receive_message_chain(:deliveries, :clear)
    end

    it 'is disabled by default' do
      load Rails.root.join('config/initializers/action_mailer_hooks.rb')

      expect(ActionMailer::Base).not_to(
        have_received(:register_interceptor).with(Gitlab::Email::Hook::SmimeSignatureInterceptor))
    end

    describe 'interceptor testbed' do
      where(:email_enabled, :email_smime_enabled, :smime_interceptor_enabled) do
        [
          [false, false, false],
          [false, true,  false],
          [true,  false, false],
          [true,  true,  true]
        ]
      end

      with_them do
        before do
          stub_config_setting(email_enabled: email_enabled)
          stub_config_setting(email_smime: { enabled: email_smime_enabled })
        end

        it 'is enabled depending on settings' do
          load Rails.root.join('config/initializers/action_mailer_hooks.rb')

          if smime_interceptor_enabled
            # Premailer must be registered before S/MIME or signatures will be mangled
            expect(ActionMailer::Base).to(
              have_received(:register_interceptor).with(::Premailer::Rails::Hook).ordered)
            expect(ActionMailer::Base).to(
              have_received(:register_interceptor).with(Gitlab::Email::Hook::SmimeSignatureInterceptor).ordered)
          else
            expect(ActionMailer::Base).not_to(
              have_received(:register_interceptor).with(Gitlab::Email::Hook::SmimeSignatureInterceptor))
          end
        end
      end
    end
  end
end
