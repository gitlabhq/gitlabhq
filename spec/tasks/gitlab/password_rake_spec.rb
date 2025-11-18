# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:password rake tasks', :silence_stdout do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/password'
  end

  describe ':reset' do
    let!(:user_1) { create(:user, username: 'foobar', password: User.random_password, password_automatically_set: true) }
    let(:password) { User.random_password }

    def stub_username(username)
      allow(Gitlab::TaskHelpers).to receive(:prompt).with('Enter username: ').and_return(username)
    end

    def stub_password(password, confirmation = nil)
      confirmation ||= password
      allow(Gitlab::TaskHelpers).to receive(:prompt_for_password).and_return(password)
      allow(Gitlab::TaskHelpers).to receive(:prompt_for_password).with('Confirm password: ').and_return(confirmation)
    end

    before do
      stub_username('foobar')
      stub_password(password)
    end

    context 'when all inputs are correct' do
      it 'updates the password properly' do
        expect(user_1.password_automatically_set?).to eq(true)

        run_rake_task('gitlab:password:reset', user_1.username)

        user_1.reload

        expect(user_1.valid_password?(password)).to eq(true)
        expect(user_1.password_automatically_set?).to eq(false)
      end
    end

    context 'when username is not provided' do
      it 'asks for username' do
        expect(Gitlab::TaskHelpers).to receive(:prompt).with('Enter username: ')

        run_rake_task('gitlab:password:reset')
      end

      context 'when username is empty' do
        it 'aborts with an error' do
          stub_username('')
          expect { run_rake_task('gitlab:password:reset') }.to raise_error(/Username can not be empty./)
        end
      end
    end

    context 'when username is passed as argument' do
      it 'does not ask for username' do
        expect(Gitlab::TaskHelpers).not_to receive(:prompt)

        run_rake_task('gitlab:password:reset', 'foobar')
      end
    end

    context 'when passwords do not match' do
      before do
        stub_password(password, User.random_password)
      end

      it 'aborts with an error' do
        expect { run_rake_task('gitlab:password:reset') }.to raise_error(%r{Unable to change password of the user with username foobar.\nPassword confirmation doesn't match Password})
      end
    end

    context 'when user cannot be found' do
      before do
        stub_username('nonexistentuser')
      end

      it 'aborts with an error' do
        expect { run_rake_task('gitlab:password:reset') }.to raise_error(/Unable to find user with username nonexistentuser./)
      end
    end
  end

  describe ":check_hashes" do
    subject(:run_rake) { run_rake_task('gitlab:password:check_hashes') }

    def pbkdf2_hash(salt_len)
      Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(
        User.random_password, 20_000, Devise.friendly_token(salt_len))
    end

    def bcrypt_hash(stretches)
      ::BCrypt::Password.create(User.random_password, cost: stretches).to_s
    end

    context 'in non fips mode' do
      let!(:unmigrated_users) do
        create(:user, username: 'unmigrated1', encrypted_password: pbkdf2_hash(64))
        create(:user, username: 'unmigrated2', encrypted_password: bcrypt_hash(3))
      end

      let!(:migrated_users) do
        create(:user, username: 'migrated1', encrypted_password: bcrypt_hash(5))
      end

      context 'with no extra argument' do
        it 'only prints the user count' do
          expect { run_rake }
            .to output("Active users with unmigrated hashes: 2 out of 3 total users\n")
            .to_stdout
        end
      end

      context 'with user printing enabled' do
        subject(:run_rake) { run_rake_task('gitlab:password:check_hashes', 'true') }

        it 'prints the user names and user count' do
          expect { run_rake }
            .to output(
              <<~MSG
            Active users with unmigrated hashes:
            unmigrated1
            unmigrated2
            Active users with unmigrated hashes: 2 out of 3 total users
              MSG
            ).to_stdout
        end
      end
    end

    context 'in fips mode', :fips_mode do
      let!(:unmigrated_users) do
        create(:user, username: 'unmigrated1', encrypted_password: pbkdf2_hash(16))
        create(:user, username: 'unmigrated2', encrypted_password: pbkdf2_hash(16))
        create(:user, username: 'unmigrated3', encrypted_password: bcrypt_hash(13))
      end

      let!(:migrated_users) do
        create(:user, username: 'migrated1', encrypted_password: pbkdf2_hash(64))
        create(:user, username: 'migrated2', encrypted_password: pbkdf2_hash(64))
      end

      context 'with no extra argument' do
        it 'only prints the user count' do
          expect { run_rake }
            .to output("Active users with unmigrated hashes: 3 out of 5 total users\n")
            .to_stdout
        end
      end

      context 'when called via alias' do
        subject(:run_rake) { run_rake_task('gitlab:password:fips_check_salts', 'true') }

        it 'invokes the hash check' do
          expect(Rake::Task['gitlab:password:check_hashes'])
            .to receive(:invoke).with('true')

          run_rake
        end
      end

      context 'with an error while inspecting a salt' do
        before do
          allow(Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512)
            .to receive(:split_digest)
            .and_raise(StandardError.new('test error'))
        end

        it 'prints an error message' do
          expect { run_rake }
            .to output(/Error getting hash for user unmigrated1: test error/)
            .to_stdout
        end
      end

      context 'with user printing enabled' do
        subject(:run_rake) { run_rake_task('gitlab:password:check_hashes', 'true') }

        it 'prints the user names and user count' do
          expect { run_rake }
            .to output(
              <<~MSG
            Active users with unmigrated hashes:
            unmigrated1
            unmigrated2
            unmigrated3
            Active users with unmigrated hashes: 3 out of 5 total users
              MSG
            ).to_stdout
        end
      end
    end
  end
end
