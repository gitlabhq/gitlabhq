# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ParameterFilters::SamlResponse, feature_category: :system_access do
  let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }

  describe "filter sensitive values" do
    let(:filtered_saml_response) do
      described_class.filter(mock_saml_response)
    end

    it 'redacts sensitive xml attributes' do
      expect(mock_saml_response).to include('2014-07')
      expect(filtered_saml_response).to include('REDACTED')
      expect(filtered_saml_response).to include('xml')
      expect(filtered_saml_response).not_to include('2014-07')
    end

    it 'redacts entire response when parsing fails' do
      invalid_xml = +"<invalid-xml>"
      filtered_invalid_xml = described_class.filter(invalid_xml)

      expect(filtered_invalid_xml).to eq('REDACTED')
    end

    it "decodes Base64 encoded SAMLResponse" do
      encoded_saml_response = Base64.strict_encode64(mock_saml_response)
      filtered_saml_response = described_class.filter(encoded_saml_response)

      expect(filtered_saml_response).to include('REDACTED')
      expect(filtered_saml_response).to include('xml')
      expect(filtered_saml_response).not_to include('2014-07')
      expect(filtered_saml_response).not_to include('2024-07')
    end

    it "returns XML" do
      expect(filtered_saml_response).to be_eql(
        <<~XML
          <?xml version="1.0"?>
          <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="pfxb9b71715-2202-9a51-8ae5-689d5b9dd25a" Version="2.0" IssueInstant="REDACTED" Destination="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685">
            <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
            <ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
              <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
              <ds:Reference URI="#pfxb9b71715-2202-9a51-8ae5-689d5b9dd25a"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>REDACTED</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>REDACTED</ds:SignatureValue>
            <ds:KeyInfo><ds:X509Data><ds:X509Certificate>MIICajCCAdOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADBSMQswCQYDVQQGEwJ1czETMBEGA1UECAwKQ2FsaWZvcm5pYTEVMBMGA1UECgwMT25lbG9naW4gSW5jMRcwFQYDVQQDDA5zcC5leGFtcGxlLmNvbTAeFw0xNDA3MTcxNDEyNTZaFw0xNTA3MTcxNDEyNTZaMFIxCzAJBgNVBAYTAnVzMRMwEQYDVQQIDApDYWxpZm9ybmlhMRUwEwYDVQQKDAxPbmVsb2dpbiBJbmMxFzAVBgNVBAMMDnNwLmV4YW1wbGUuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZx+ON4IUoIWxgukTb1tOiX3bMYzYQiwWPUNMp+Fq82xoNogso2bykZG0yiJm5o8zv/sd6pGouayMgkx/2FSOdc36T0jGbCHuRSbtia0PEzNIRtmViMrt3AeoWBidRXmZsxCNLwgIV6dn2WpuE5Az0bHgpZnQxTKFek0BMKU/d8wIDAQABo1AwTjAdBgNVHQ4EFgQUGHxYqZYyX7cTxKVODVgZwSTdCnwwHwYDVR0jBBgwFoAUGHxYqZYyX7cTxKVODVgZwSTdCnwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQ0FAAOBgQByFOl+hMFICbd3DJfnp2Rgd/dqttsZG/tyhILWvErbio/DEe98mXpowhTkC04ENprOyXi7ZbUqiicF89uAGyt1oqgTUCD1VsLahqIcmrzgumNyTwLGWo17WDAa1/usDhetWAMhgzF/Cnf5ek0nK00m0YZGyc4LzgD0CROMASTWNg==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature>
            <samlp:Status>
              <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
            </samlp:Status>
            <saml:Assertion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="_d71a3a8e9fcc45c9e9d248ef7049393fc8f04e5f75" Version="2.0" IssueInstant="REDACTED">
              <saml:Issuer>http://idp.example.com/metadata.php</saml:Issuer>
              <saml:Subject>
                <saml:NameID SPNameQualifier="http://sp.example.com/demo1/metadata.php" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient">_ce3d2948b4cf20146dee0a0b3dd6f69b6cf86f62d7</saml:NameID>
                <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
                  <saml:SubjectConfirmationData NotOnOrAfter="2024-01-18T06:21:48Z" Recipient="http://sp.example.com/demo1/index.php?acs" InResponseTo="ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685"/>
                </saml:SubjectConfirmation>
              </saml:Subject>
              <saml:Conditions NotBefore="REDACTED" NotOnOrAfter="REDACTED">
                <saml:AudienceRestriction>
                  <saml:Audience>http://sp.example.com/demo1/metadata.php</saml:Audience>
                </saml:AudienceRestriction>
              </saml:Conditions>
              <saml:AuthnStatement AuthnInstant="REDACTED" SessionNotOnOrAfter="REDACTED" SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf93">
                <saml:AuthnContext>
                  <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
                </saml:AuthnContext>
              </saml:AuthnStatement>
              <saml:AttributeStatement>
                <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                  <saml:AttributeValue xsi:type="xs:string">test</saml:AttributeValue>
                </saml:Attribute>
                <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                  <saml:AttributeValue xsi:type="xs:string">test@example.com</saml:AttributeValue>
                </saml:Attribute>
                <saml:Attribute Name="eduPersonAffiliation" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                  <saml:AttributeValue xsi:type="xs:string">users</saml:AttributeValue>
                  <saml:AttributeValue xsi:type="xs:string">examplerole1</saml:AttributeValue>
                </saml:Attribute>
              </saml:AttributeStatement>
            </saml:Assertion>
          </samlp:Response>
        XML
      )
    end
  end
end
