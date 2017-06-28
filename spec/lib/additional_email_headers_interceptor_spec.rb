require 'spec_helper'

describe AdditionalEmailHeadersInterceptor do
  it 'adds Auto-Submitted header' do
    mail = ActionMailer::Base.mail(to: 'test@mail.com', from: 'info@mail.com', body: 'hello').deliver

    expect(mail.header['To'].value).to eq('test@mail.com')
    expect(mail.header['From'].value).to eq('info@mail.com')
    expect(mail.header['Auto-Submitted'].value).to eq('auto-generated')
    expect(mail.header['X-Auto-Response-Suppress'].value).to eq('All')
  end
end
