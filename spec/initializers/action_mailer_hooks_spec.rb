require 'spec_helper'

describe 'ActionMailer hooks' do
  describe 'smime signature interceptor' do
    before do
      class_spy(ActionMailer::Base).as_stubbed_const
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
            expect(ActionMailer::Base).to(
              have_received(:register_interceptor).with(Gitlab::Email::Hook::SmimeSignatureInterceptor))
          else
            expect(ActionMailer::Base).not_to(
              have_received(:register_interceptor).with(Gitlab::Email::Hook::SmimeSignatureInterceptor))
          end
        end
      end
    end
  end
end
