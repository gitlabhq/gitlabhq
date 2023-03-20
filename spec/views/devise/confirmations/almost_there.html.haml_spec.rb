# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/confirmations/almost_there' do
  subject { render(template: 'devise/confirmations/almost_there') }

  describe 'confirmations text' do
    before do
      allow(view).to receive(:params).and_return(email: email)
    end

    context 'when correct email' do
      let(:email) { 'こんにちは@test' }

      specify do
        subject

        expect(rendered).to have_content(
          "Please check your email (#{email}) to confirm your account"
        )
      end
    end

    context 'when random text' do
      let(:email) { 'random text' }

      specify do
        subject

        expect(rendered).to have_content(
          'Please check your email to confirm your account'
        )
      end
    end
  end

  describe 'register again prompt' do
    specify do
      subject

      expect(rendered).to have_content(
        'If the email address is incorrect, you can register again with a different email'
      )
      expect(rendered).to have_link(
        'register again with a different email', href: new_user_registration_path
      )
    end
  end
end
