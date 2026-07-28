# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:mcp namespace rake tasks', :silence_stdout, feature_category: :mcp_server do
  let(:task_name) { 'gitlab:mcp:verify_setup' }
  let(:verify_instance) { instance_double(Gitlab::Mcp::Administration::VerifyMcpServerSetup) }

  subject(:task) { Rake::Task[task_name] }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/mcp'
  end

  before do
    Rake::Task.define_task(:gitlab_environment)
    allow(Gitlab::Mcp::Administration::VerifyMcpServerSetup).to receive(:new).and_return(verify_instance)
    allow(verify_instance).to receive(:execute)
  end

  describe 'mcp:verify_setup' do
    it 'creates a VerifyMcpServerSetup instance with the username and calls execute' do
      expect(Gitlab::Mcp::Administration::VerifyMcpServerSetup).to receive(:new)
        .with('testuser')
        .and_return(verify_instance)
      expect(verify_instance).to receive(:execute)

      run_rake_task(task_name, 'testuser')
    end

    it 'passes nil when no username is provided' do
      expect(Gitlab::Mcp::Administration::VerifyMcpServerSetup).to receive(:new)
        .with(nil)
        .and_return(verify_instance)
      expect(verify_instance).to receive(:execute)

      run_rake_task(task_name)
    end
  end
end
