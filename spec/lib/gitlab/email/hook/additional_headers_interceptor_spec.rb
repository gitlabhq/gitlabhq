# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::AdditionalHeadersInterceptor do
  let(:mail) do
    ActionMailer::Base.mail(to: 'test@mail.com', from: 'info@mail.com', body: 'hello')
  end

  before do
    mail.deliver_now
  end

  it 'adds Auto-Submitted header' do
    expect(mail.header['To'].value).to eq('test@mail.com')
    expect(mail.header['From'].value).to eq('info@mail.com')
    expect(mail.header['Auto-Submitted'].value).to eq('auto-generated')
    expect(mail.header['X-Auto-Response-Suppress'].value).to eq('All')
  end

  context 'when the same mail object is sent twice' do
    before do
      mail.deliver_now
    end

    it 'does not add the Auto-Submitted header twice' do
      expect(mail.header['Auto-Submitted'].value).to eq('auto-generated')
      expect(mail.header['X-Auto-Response-Suppress'].value).to eq('All')
    end
  end
end
