# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509Helper do
  describe '#x509_subject' do
    let(:search_uppercase) { %w[CN OU O] }
    let(:search_lowercase) { %w[cn ou o] }
    let(:certificate_attributes) do
      {
        'CN' => 'CA Issuing',
        'OU' => 'Trust Center',
        'O' => 'Example'
      }
    end

    context 'with uppercase DN' do
      let(:upper_dn) { 'CN=CA Issuing,OU=Trust Center,O=Example,L=World,C=Galaxy' }

      it 'returns the attributes on any case search' do
        expect(x509_subject(upper_dn, search_lowercase)).to eq(certificate_attributes)
        expect(x509_subject(upper_dn, search_uppercase)).to eq(certificate_attributes)
      end
    end

    context 'with lowercase DN' do
      let(:lower_dn) { 'cn=CA Issuing,ou=Trust Center,o=Example,l=World,c=Galaxy' }

      it 'returns the attributes on any case search' do
        expect(x509_subject(lower_dn, search_lowercase)).to eq(certificate_attributes)
        expect(x509_subject(lower_dn, search_uppercase)).to eq(certificate_attributes)
      end
    end

    context 'with comma within DN' do
      let(:comma_dn) { 'cn=CA\, Issuing,ou=Trust Center,o=Example,l=World,c=Galaxy' }
      let(:certificate_attributes) do
        {
          'CN' => 'CA, Issuing',
          'OU' => 'Trust Center',
          'O' => 'Example'
        }
      end

      it 'returns the attributes on any case search' do
        expect(x509_subject(comma_dn, search_lowercase)).to eq(certificate_attributes)
        expect(x509_subject(comma_dn, search_uppercase)).to eq(certificate_attributes)
      end
    end

    context 'with mal formed DN' do
      let(:bad_dn) { 'cn=CA, Issuing,ou=Trust Center,o=Example,l=World,c=Galaxy' }

      it 'returns nil on any case search' do
        expect(x509_subject(bad_dn, search_lowercase)).to eq({})
        expect(x509_subject(bad_dn, search_uppercase)).to eq({})
      end
    end
  end
end
