require 'spec_helper'
require 'rake'

describe 'gitlab:users namespace rake task' do
  let(:enable_registry) { true }

  before :all do
    Rake.application.rake_require 'tasks/gitlab/task_helpers'
    Rake.application.rake_require 'tasks/gitlab/users'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end

  describe 'clear_all_authentication_tokens' do
    before do
      # avoid writing task output to spec progress
      allow($stdout).to receive :write
    end

    context 'gitlab version' do
      it 'clears the authentication token for all users' do
        create_list(:user, 2)

        expect(User.pluck(:authentication_token)).to all(be_present)

        run_rake_task('gitlab:users:clear_all_authentication_tokens')

        expect(User.pluck(:authentication_token)).to all(be_nil)
      end
    end
  end
end
