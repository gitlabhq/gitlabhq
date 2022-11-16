# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/confirmations/almost_there' do
  describe 'confirmations text' do
    subject { render(template: 'devise/confirmations/almost_there') }

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
end
