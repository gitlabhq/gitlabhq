require 'spec_helper'
require 'omniauth/strategies/kerberos_spnego'

describe OmniAuth::Strategies::KerberosSpnego do
  subject { described_class.new(:app) }
  let(:session) { Hash.new }

  before do
    allow(subject).to receive(:session).and_return(session)
  end

  it 'uses the principal name as the "uid"' do
    session[:kerberos_spnego_principal_name] = 'Janedoe@FOOBAR.COM'
    expect(subject.uid).to eq('Janedoe@FOOBAR.COM')
  end

  it 'extracts the username' do
    session[:kerberos_spnego_principal_name] = 'Janedoe@FOOBAR.COM'
    expect(subject.username).to eq('Janedoe')
  end

  it 'turns the principal name into an email address' do
    session[:kerberos_spnego_principal_name] = 'Janedoe@FOOBAR.COM'
    expect(subject.email).to eq('Janedoe@foobar.com')
  end

  it 'clears its special session key' do
    session[:kerberos_spnego_principal_name] = 'Janedoe@FOOBAR.COM'
    subject.username
    expect(session).to eq({})
  end
end
