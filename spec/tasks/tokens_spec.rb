require 'rake_helper'

describe 'tokens rake tasks' do
  let!(:user) { create(:user) }

  before do
    Rake.application.rake_require 'tasks/tokens'
  end

  describe 'reset_all_email task' do
    it 'invokes create_hooks task' do
      expect { run_rake_task('tokens:reset_all_email') }.to change { user.reload.incoming_email_token }
    end
  end

  describe 'reset_all_rss task' do
    it 'invokes create_hooks task' do
      expect { run_rake_task('tokens:reset_all_rss') }.to change { user.reload.rss_token }
    end
  end
end
