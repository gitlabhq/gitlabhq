# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'tokens rake tasks', :silence_stdout do
  let!(:user) { create(:user) }

  before do
    Rake.application.rake_require 'tasks/tokens'
  end

  describe 'reset_all_email task' do
    it 'changes the incoming email token' do
      expect { run_rake_task('tokens:reset_all_email') }.to change { user.reload.incoming_email_token }
    end
  end

  describe 'reset_all_feed task' do
    it 'changes the feed token for the user' do
      expect { run_rake_task('tokens:reset_all_feed') }.to change { user.reload.feed_token }
    end
  end
end
