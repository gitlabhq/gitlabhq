# frozen_string_literal: true

require 'spec_helper'

# We need to load the constants here, or else stubbed
# constants will be overwritten when `require 'git'`
# is hit in the rake task.
require 'git'

RSpec.describe 'gitlab:security namespace rake tasks', :silence_stdout, feature_category: :user_management do
  let(:fixture_path) { Rails.root.join('spec/fixtures/tasks/gitlab/security') }
  let(:output_file) { File.join(__dir__, 'tmp/banned_keys_test.yml') }
  let(:git_url) { 'https://github.com/rapid7/ssh-badkeys.git' }
  let(:mock_git) { class_double('Git') }

  subject(:execute) { run_rake_task('gitlab:security:update_banned_ssh_keys', git_url, output_file) }

  before do
    Rake.application.rake_require 'tasks/gitlab/security/update_banned_ssh_keys'
    stub_const('Git', mock_git)
    allow(Dir).to receive(:mktmpdir).and_return(fixture_path)
    allow(mock_git).to receive(:clone)
  end

  around do |example|
    test_dir = File.dirname(output_file)
    FileUtils.mkdir_p(test_dir)

    example.run

    FileUtils.rm_rf(test_dir)
  end

  it 'adds banned keys when clone is successful' do
    expect(mock_git).to receive(:clone).with(git_url, 'ssh-badkeys', path: fixture_path)

    execute

    actual = File.read(output_file)
    expected = File.read(File.join(fixture_path, 'expected_banned_keys.yml'))
    expect(actual).to eq(expected)
  end

  it 'exits when clone fails' do
    expect(mock_git).to receive(:clone).with(git_url, 'ssh-badkeys', path: fixture_path).and_raise(RuntimeError)

    expect { execute }.to raise_error(SystemExit)
  end

  it 'exits when max config size reaches' do
    stub_const('MAX_CONFIG_SIZE', 0.bytes)
    expect(mock_git).to receive(:clone).with(git_url, 'ssh-badkeys', path: fixture_path)

    expect { execute }.to output(/banned_ssh_keys.yml has grown too large - halting execution/).to_stdout
  end
end
