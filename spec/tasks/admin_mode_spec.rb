# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'admin mode on tasks', :silence_stdout do
  before do
    allow(::Gitlab::Runtime).to receive(:test_suite?).and_return(false)
    allow(::Gitlab::Runtime).to receive(:rake?).and_return(true)
  end

  shared_examples 'verify admin mode' do |state|
    it 'matches the expected admin mode' do
      Rake::Task.define_task :verify_admin_mode do
        expect(Gitlab::Auth::CurrentUserMode.new(user).admin_mode?).to be(state)
      end

      run_rake_task('verify_admin_mode')
    end
  end

  describe 'with a regular user' do
    let(:user) { create(:user) }

    include_examples 'verify admin mode', false
  end

  describe 'with an admin' do
    let(:user) { create(:admin) }

    include_examples 'verify admin mode', true
  end
end
