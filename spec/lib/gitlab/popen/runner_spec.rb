# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Popen::Runner do
  subject { described_class.new }

  describe '#run' do
    it 'runs the command and returns the result' do
      run_command

      expect(Gitlab::Popen).to have_received(:popen_with_detail)
    end
  end

  describe '#all_success_and_clean?' do
    it 'returns true when exit status is 0 and stderr is empty' do
      run_command

      expect(subject).to be_all_success_and_clean
    end

    it 'returns false when exit status is not 0' do
      run_command(exitstatus: 1)

      expect(subject).not_to be_all_success_and_clean
    end

    it 'returns false when exit stderr has something' do
      run_command(stderr: 'stderr')

      expect(subject).not_to be_all_success_and_clean
    end
  end

  describe '#all_success?' do
    it 'returns true when exit status is 0' do
      run_command

      expect(subject).to be_all_success
    end

    it 'returns false when exit status is not 0' do
      run_command(exitstatus: 1)

      expect(subject).not_to be_all_success
    end

    it 'returns true' do
      run_command(stderr: 'stderr')

      expect(subject).to be_all_success
    end
  end

  describe '#all_stderr_empty?' do
    it 'returns true when stderr is empty' do
      run_command

      expect(subject).to be_all_stderr_empty
    end

    it 'returns true when exit status is not 0' do
      run_command(exitstatus: 1)

      expect(subject).to be_all_stderr_empty
    end

    it 'returns false when exit stderr has something' do
      run_command(stderr: 'stderr')

      expect(subject).not_to be_all_stderr_empty
    end
  end

  describe '#failed_results' do
    it 'returns [] when everything is passed' do
      run_command

      expect(subject.failed_results).to be_empty
    end

    it 'returns the result when exit status is not 0' do
      result = run_command(exitstatus: 1)

      expect(subject.failed_results).to contain_exactly(result)
    end

    it 'returns [] when exit stderr has something' do
      run_command(stderr: 'stderr')

      expect(subject.failed_results).to be_empty
    end
  end

  describe '#warned_results' do
    it 'returns [] when everything is passed' do
      run_command

      expect(subject.warned_results).to be_empty
    end

    it 'returns [] when exit status is not 0' do
      run_command(exitstatus: 1)

      expect(subject.warned_results).to be_empty
    end

    it 'returns the result when exit stderr has something' do
      result = run_command(stderr: 'stderr')

      expect(subject.warned_results).to contain_exactly(result)
    end
  end

  def run_command(
    command: 'command',
    stdout: 'stdout',
    stderr: '',
    exitstatus: 0,
    status: double(exitstatus: exitstatus, success?: exitstatus == 0),
    duration: 0.1)

    result =
      Gitlab::Popen::Result.new(command, stdout, stderr, status, duration)

    allow(Gitlab::Popen)
      .to receive(:popen_with_detail)
      .and_return(result)

    subject.run([command]) do |cmd, &run|
      expect(cmd).to eq(command)

      cmd_result = run.call

      expect(cmd_result).to eq(result)
    end

    subject.results.first
  end
end
