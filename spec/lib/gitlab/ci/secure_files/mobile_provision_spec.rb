# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::SecureFiles::MobileProvision do
  context 'when the supplied profile cannot be parsed' do
    context 'when the supplied certificate cannot be parsed' do
      let(:invalid_profile) { described_class.new('xyzabc') }

      describe '#decoded_plist' do
        it 'assigns the error message and returns nil' do
          expect(invalid_profile.decoded_plist).to be nil
          expect(invalid_profile.error).to eq('Could not parse the PKCS7: no start line (Expecting: PKCS7)')
        end
      end

      describe '#properties' do
        it 'returns nil' do
          expect(invalid_profile.properties).to be_nil
        end
      end

      describe '#metadata' do
        it 'returns an empty hash' do
          expect(invalid_profile.metadata).to eq({})
        end
      end

      describe '#expires_at' do
        it 'returns nil' do
          expect(invalid_profile.metadata[:expires_at]).to be_nil
        end
      end
    end
  end

  context 'when the supplied profile can be parsed' do
    let(:sample_file) { fixture_file('ci_secure_files/sample.mobileprovision') }
    let(:subject) { described_class.new(sample_file) }

    describe '#decoded_plist' do
      it 'returns an XML string' do
        expect(subject.decoded_plist.class).to be(String)
        expect(subject.decoded_plist.starts_with?('<?xml version="1.0"')).to be true
      end
    end

    describe '#properties' do
      it 'returns the property list of the decoded plist provided' do
        expect(subject.properties.class).to be(Hash)
        expect(subject.properties.keys).to match_array(%w[AppIDName ApplicationIdentifierPrefix CreationDate
                                                          Platform IsXcodeManaged DeveloperCertificates
                                                          DER-Encoded-Profile PPQCheck Entitlements ExpirationDate
                                                          Name ProvisionedDevices TeamIdentifier TeamName
                                                          TimeToLive UUID Version])
      end

      it 'returns nil if the property list fails to be parsed from the decoded plist' do
        allow(subject).to receive(:decoded_plist).and_return('foo/bar')
        expect(subject.properties).to be nil
        expect(subject.error).to start_with('invalid XML')
      end
    end

    describe '#metadata' do
      it 'returns a hash with the expected keys' do
        expect(subject.metadata.keys).to match_array([:id, :expires_at, :app_id, :app_id_prefix, :app_name,
                                                      :certificate_ids, :devices, :entitlements, :platforms,
                                                      :team_id, :team_name, :xcode_managed])
      end
    end

    describe '#id' do
      it 'returns the profile UUID' do
        expect(subject.metadata[:id]).to eq('6b9fcce1-b9a9-4b37-b2ce-ec4da2044abf')
      end
    end

    describe '#expires_at' do
      it 'returns the expiration timestamp of the profile' do
        expect(subject.metadata[:expires_at].utc).to eq('2023-08-01 23:15:13 UTC')
      end
    end

    describe '#platforms' do
      it 'returns the platforms assigned to the profile' do
        expect(subject.metadata[:platforms]).to match_array(['iOS'])
      end
    end

    describe '#team_name' do
      it 'returns the team name in the profile' do
        expect(subject.metadata[:team_name]).to eq('Darby Frey')
      end
    end

    describe '#team_id' do
      it 'returns the team ids in the profile' do
        expect(subject.metadata[:team_id]).to match_array(['N7SYAN8PX8'])
      end
    end

    describe '#app_name' do
      it 'returns the app name in the profile' do
        expect(subject.metadata[:app_name]).to eq('iOS Demo')
      end
    end

    describe '#app_id' do
      it 'returns the app id in the profile' do
        expect(subject.metadata[:app_id]).to eq('match Development com.gitlab.ios-demo')
      end
    end

    describe '#app_id_prefix' do
      it 'returns the app id prefixes in the profile' do
        expect(subject.metadata[:app_id_prefix]).to match_array(['N7SYAN8PX8'])
      end
    end

    describe '#xcode_managed' do
      it 'returns the xcode_managed property in the profile' do
        expect(subject.metadata[:xcode_managed]).to be false
      end
    end

    describe '#entitlements' do
      it 'returns the entitlements in the profile' do
        expect(subject.metadata[:entitlements].keys).to match_array(['application-identifier',
                                                                     'com.apple.developer.game-center',
                                                                     'com.apple.developer.team-identifier',
                                                                     'get-task-allow',
                                                                     'keychain-access-groups'])
      end
    end

    describe '#devices' do
      it 'returns the devices attached to the profile' do
        expect(subject.metadata[:devices]).to match_array(["00008101-001454860C10001E"])
      end
    end

    describe '#certificate_ids' do
      it 'returns the certificate ids attached to the profile' do
        expect(subject.metadata[:certificate_ids]).to match_array(["23380136242930206312716563638445789376"])
      end
    end
  end
end
