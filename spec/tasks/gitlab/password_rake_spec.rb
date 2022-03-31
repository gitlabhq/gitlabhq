# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:password rake tasks', :silence_stdout do
  let_it_be(:user_1) { create(:user, username: 'foobar', password: 'initial_password') }

  def stub_username(username)
    allow(Gitlab::TaskHelpers).to receive(:prompt).with('Enter username: ').and_return(username)
  end

  def stub_password(password, confirmation = nil)
    confirmation ||= password
    allow(Gitlab::TaskHelpers).to receive(:prompt_for_password).and_return(password)
    allow(Gitlab::TaskHelpers).to receive(:prompt_for_password).with('Confirm password: ').and_return(confirmation)
  end

  before do
    Rake.application.rake_require 'tasks/gitlab/password'

    stub_username('foobar')
    stub_password('secretpassword')
  end

  describe ':reset' do
    context 'when all inputs are correct' do
      it 'updates the password properly' do
        run_rake_task('gitlab:password:reset', user_1.username)
        expect(user_1.reload.valid_password?('secretpassword')).to eq(true)
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
        stub_password('randompassword', 'differentpassword')
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
end
