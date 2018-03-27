require 'rails_helper'

describe Gitlab::Gpg do
  describe '.fingerprints_from_key' do
    before do
      # make sure that each method is using the temporary keychain
      expect(described_class).to receive(:using_tmp_keychain).and_call_original
    end

    it 'returns CurrentKeyChain.fingerprints_from_key' do
      expect(Gitlab::Gpg::CurrentKeyChain).to receive(:fingerprints_from_key).with(GpgHelpers::User1.public_key)

      described_class.fingerprints_from_key(GpgHelpers::User1.public_key)
    end
  end

  describe '.primary_keyids_from_key' do
    it 'returns the keyid' do
      expect(
        described_class.primary_keyids_from_key(GpgHelpers::User1.public_key)
      ).to eq [GpgHelpers::User1.primary_keyid]
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.primary_keyids_from_key('bogus')
      ).to eq []
    end
  end

  describe '.subkeys_from_key' do
    it 'returns the subkeys by primary key' do
      all_subkeys = described_class.subkeys_from_key(GpgHelpers::User1.public_key)
      subkeys = all_subkeys[GpgHelpers::User1.primary_keyid]

      expect(subkeys).to be_present
      expect(subkeys.first[:keyid]).to be_present
      expect(subkeys.first[:fingerprint]).to be_present
    end

    it 'returns an empty array when there are not subkeys' do
      all_subkeys = described_class.subkeys_from_key(GpgHelpers::User4.public_key)

      expect(all_subkeys[GpgHelpers::User4.primary_keyid]).to be_empty
    end
  end

  describe '.user_infos_from_key' do
    it 'returns the names and emails' do
      user_infos = described_class.user_infos_from_key(GpgHelpers::User1.public_key)
      expect(user_infos).to eq([{
        name: GpgHelpers::User1.names.first,
        email: GpgHelpers::User1.emails.first
      }])
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.user_infos_from_key('bogus')
      ).to eq []
    end

    it 'downcases the email' do
      public_key = double(:key)
      fingerprints = double(:fingerprints)
      uid = double(:uid, name: 'Nannie Bernhard', email: 'NANNIE.BERNHARD@EXAMPLE.COM')
      raw_key = double(:raw_key, uids: [uid])
      allow(Gitlab::Gpg::CurrentKeyChain).to receive(:fingerprints_from_key).with(public_key).and_return(fingerprints)
      allow(GPGME::Key).to receive(:find).with(:public, anything).and_return([raw_key])

      user_infos = described_class.user_infos_from_key(public_key)
      expect(user_infos).to eq([{
        name: 'Nannie Bernhard',
        email: 'nannie.bernhard@example.com'
      }])
    end
  end

  describe '.current_home_dir' do
    let(:default_home_dir) { GPGME::Engine.dirinfo('homedir') }

    it 'returns the default value when no explicit home dir has been set' do
      expect(described_class.current_home_dir).to eq default_home_dir
    end

    it 'returns the explicitely set home dir' do
      GPGME::Engine.home_dir = '/tmp/gpg'

      expect(described_class.current_home_dir).to eq '/tmp/gpg'

      GPGME::Engine.home_dir = GPGME::Engine.dirinfo('homedir')
    end

    it 'returns the default value when explicitely setting the home dir to nil' do
      GPGME::Engine.home_dir = nil

      expect(described_class.current_home_dir).to eq default_home_dir
    end
  end

  describe '.using_tmp_keychain' do
    it "the second thread does not change the first thread's directory" do
      thread1 = Thread.new do
        described_class.using_tmp_keychain do
          dir = described_class.current_home_dir
          sleep 0.1
          expect(described_class.current_home_dir).to eq dir
        end
      end

      thread2 = Thread.new do
        described_class.using_tmp_keychain do
          sleep 0.2
        end
      end

      thread1.join
      thread2.join
    end

    it 'allows recursive execution in the same thread' do
      expect do
        described_class.using_tmp_keychain do
          described_class.using_tmp_keychain do
          end
        end
      end.not_to raise_error(ThreadError)
    end
  end
end

describe Gitlab::Gpg::CurrentKeyChain do
  around do |example|
    Gitlab::Gpg.using_tmp_keychain do
      example.run
    end
  end

  describe '.add' do
    it 'stores the key in the keychain' do
      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).to eq []

      described_class.add(GpgHelpers::User1.public_key)

      keys = GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)
      expect(keys.count).to eq 1
      expect(keys.first).to have_attributes(
        email: GpgHelpers::User1.emails.first,
        fingerprint: GpgHelpers::User1.fingerprint
      )
    end
  end

  describe '.fingerprints_from_key' do
    it 'returns the fingerprint' do
      expect(
        described_class.fingerprints_from_key(GpgHelpers::User1.public_key)
      ).to eq [GpgHelpers::User1.fingerprint]
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.fingerprints_from_key('bogus')
      ).to eq []
    end
  end
end
