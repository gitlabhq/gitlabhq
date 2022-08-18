# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gpg do
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
      uid = double(:uid, name: +'Nannie Bernhard', email: +'NANNIE.BERNHARD@EXAMPLE.COM')
      raw_key = double(:raw_key, uids: [uid])
      allow(Gitlab::Gpg::CurrentKeyChain).to receive(:fingerprints_from_key).with(public_key).and_return(fingerprints)
      allow(GPGME::Key).to receive(:find).with(:public, anything).and_return([raw_key])

      user_infos = described_class.user_infos_from_key(public_key)
      expect(user_infos).to eq([{
        name: 'Nannie Bernhard',
        email: 'nannie.bernhard@example.com'
      }])
    end

    it 'rejects non UTF-8 names and addresses' do
      public_key = double(:key)
      fingerprints = double(:fingerprints)
      email = (+"\xEEch@test.com").force_encoding('ASCII-8BIT')
      uid = double(:uid, name: +'Test User', email: email)
      raw_key = double(:raw_key, uids: [uid])
      allow(Gitlab::Gpg::CurrentKeyChain).to receive(:fingerprints_from_key).with(public_key).and_return(fingerprints)
      allow(GPGME::Key).to receive(:find).with(:public, anything).and_return([raw_key])

      user_infos = described_class.user_infos_from_key(public_key)
      expect(user_infos).to eq([])
    end
  end

  describe '.current_home_dir' do
    let(:default_home_dir) { GPGME::Engine.dirinfo('homedir') }

    it 'returns the default value when no explicit home dir has been set' do
      expect(described_class.current_home_dir).to eq default_home_dir
    end

    it 'returns the explicitly set home dir' do
      GPGME::Engine.home_dir = '/tmp/gpg'

      expect(described_class.current_home_dir).to eq '/tmp/gpg'

      GPGME::Engine.home_dir = GPGME::Engine.dirinfo('homedir')
    end

    it 'returns the default value when explicitly setting the home dir to nil' do
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
      end.not_to raise_error
    end

    it 'keeps track of created and removed keychains in counters' do
      created = Gitlab::Metrics.counter(:gpg_tmp_keychains_created_total, 'The number of temporary GPG keychains')
      removed = Gitlab::Metrics.counter(:gpg_tmp_keychains_removed_total, 'The number of temporary GPG keychains')

      initial_created = created.get
      initial_removed = removed.get

      described_class.using_tmp_keychain do
        expect(created.get).to eq(initial_created + 1)
        expect(removed.get).to eq(initial_removed)
      end

      expect(removed.get).to eq(initial_removed + 1)
    end

    it 'cleans up the tmp directory after finishing' do
      tmp_directory = nil

      described_class.using_tmp_keychain do
        tmp_directory = described_class.current_home_dir
        expect(File.exist?(tmp_directory)).to be true
      end

      expect(tmp_directory).not_to be_nil
      expect(File.exist?(tmp_directory)).to be false
    end

    it 'does not fail if the homedir was deleted while running' do
      expect do
        described_class.using_tmp_keychain do
          FileUtils.remove_entry(described_class.current_home_dir)
        end
      end.not_to raise_error
    end

    it 'tracks an exception when cleaning up the tmp dir fails' do
      expected_exception = described_class::CleanupError.new('cleanup failed')
      expected_tmp_dir = nil

      expect(described_class).to receive(:cleanup_tmp_dir).and_raise(expected_exception)
      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      described_class.using_tmp_keychain do
        expected_tmp_dir = described_class.current_home_dir
        FileUtils.touch(File.join(expected_tmp_dir, 'dummy.file'))
      end

      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception).with(
        expected_exception,
        issue_url: 'https://gitlab.com/gitlab-org/gitlab/issues/20918',
        tmp_dir: expected_tmp_dir, contents: ['dummy.file']
      )
    end

    shared_examples 'multiple deletion attempts of the tmp-dir' do |seconds|
      let(:tmp_dir) do
        tmp_dir = Dir.mktmpdir
        allow(Dir).to receive(:mktmpdir).and_return(tmp_dir)
        tmp_dir
      end

      before do
        # Stub all the other calls for `remove_entry`
        allow(FileUtils).to receive(:remove_entry).with(any_args).and_call_original
      end

      it "tries for #{seconds} or 15 times" do
        expect(Retriable).to receive(:retriable).with(a_hash_including(max_elapsed_time: seconds, tries: 15))

        described_class.using_tmp_keychain {}
      end

      it 'tries at least 2 times to remove the tmp dir before raising', :aggregate_failures do
        expect(Retriable).to receive(:sleep).at_least(:twice)
        expect(FileUtils).to receive(:remove_entry).with(tmp_dir).at_least(:twice).and_raise('Deletion failed')

        expect { described_class.using_tmp_keychain {} }.to raise_error(described_class::CleanupError)
      end

      it 'does not attempt multiple times when the deletion succeeds' do
        expect(Retriable).to receive(:sleep).once
        expect(FileUtils).to receive(:remove_entry).with(tmp_dir).once.and_raise('Deletion failed')
        expect(FileUtils).to receive(:remove_entry).with(tmp_dir).and_call_original

        expect { described_class.using_tmp_keychain {} }.not_to raise_error

        expect(File.exist?(tmp_dir)).to be false
      end
    end

    it_behaves_like 'multiple deletion attempts of the tmp-dir', described_class::FG_CLEANUP_RUNTIME_S

    context 'when running in Sidekiq' do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      it_behaves_like 'multiple deletion attempts of the tmp-dir', described_class::BG_CLEANUP_RUNTIME_S
    end
  end
end

RSpec.describe Gitlab::Gpg::CurrentKeyChain do
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
