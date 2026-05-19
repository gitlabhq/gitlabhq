# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bundler rake tasks', :silence_stdout, feature_category: :tooling do
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  before do
    Rake.application.rake_require 'tasks/bundler'
    allow(Bundler).to receive(:with_original_env).and_yield
    allow(Open3).to receive(:capture3).and_return(['', '', success_status])
  end

  describe 'bundler:gemfile:sync' do
    subject(:run_task) { run_rake_task('bundler:gemfile:sync') }

    context 'when all commands succeed' do
      it 'runs all required bundler commands in order' do
        expect(Open3).to receive(:capture3).with('bundle install').ordered.and_return(['', '', success_status])
        expect(Open3).to receive(:capture3).with('cp Gemfile.lock Gemfile.next.lock').ordered.and_return(['', '',
          success_status])
        expect(Open3).to receive(:capture3).with('BUNDLE_GEMFILE=Gemfile.next bundle lock').ordered.and_return(['', '',
          success_status])
        expect(Open3).to receive(:capture3).with('BUNDLE_GEMFILE=Gemfile.next bundle install').ordered.and_return(['',
          '', success_status])

        run_task
      end
    end

    context 'when bundle install fails' do
      before do
        allow(Open3).to receive(:capture3).with('bundle install').and_return(['', 'error', failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution.with_message('installing Gemfile failed')
      end
    end

    context 'when cp Gemfile.lock fails' do
      before do
        allow(Open3).to receive(:capture3).with('cp Gemfile.lock Gemfile.next.lock').and_return(['', 'error',
          failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution.with_message('copying Gemfile.lock to Gemfile.next.lock failed')
      end
    end

    context 'when BUNDLE_GEMFILE=Gemfile.next bundle lock fails' do
      before do
        allow(Open3).to receive(:capture3).with('BUNDLE_GEMFILE=Gemfile.next bundle lock').and_return(['', 'error',
          failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution.with_message('updating Gemfile.next failed')
      end
    end

    context 'when BUNDLE_GEMFILE=Gemfile.next bundle install fails' do
      before do
        allow(Open3).to receive(:capture3).with('BUNDLE_GEMFILE=Gemfile.next bundle install').and_return(['', 'error',
          failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution.with_message('installing Gemfile.next failed')
      end
    end

    context 'when FROM_LEFTHOOK env var is set to 1' do
      before do
        stub_env('FROM_LEFTHOOK', '1')
      end

      it 'suppresses output' do
        run_task
        expect($stdout.string).to be_empty
      end

      context 'when a command fails' do
        before do
          allow(Open3).to receive(:capture3).with('bundle install').and_return(['some output', 'some error',
            failure_status])
        end

        it 'suppresses output' do
          expect { run_task }.to abort_execution
          expect($stdout.string).to be_empty
        end
      end
    end

    context 'when FROM_LEFTHOOK env var is set to true' do
      before do
        stub_env('FROM_LEFTHOOK', 'true')
      end

      it 'suppresses output' do
        run_task
        expect($stdout.string).to be_empty
      end
    end
  end

  describe 'bundler:gemfile:check' do
    subject(:run_task) { run_rake_task('bundler:gemfile:check') }

    context 'when all commands succeed' do
      it 'runs all required check commands in order' do
        expect(Open3).to receive(:capture3)
          .with('bundle lock --print | diff Gemfile.lock -')
          .ordered
          .and_return(['', '', success_status])

        expect(Open3).to receive(:capture3)
          .with('BUNDLE_GEMFILE=Gemfile.next bundle lock --print --lockfile Gemfile.lock | diff Gemfile.next.lock -')
          .ordered
          .and_return(['', '', success_status])

        run_task
      end
    end

    context 'when Gemfile.lock is inconsistent' do
      before do
        allow(Open3).to receive(:capture3)
          .with('bundle lock --print | diff Gemfile.lock -')
          .and_return(['diff output', '', failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution
          .with_message('inconsistent Gemfile.lock detected, run `bundle exec rake bundler:gemfile:sync`')
      end
    end

    context 'when Gemfile.next.lock is inconsistent' do
      before do
        allow(Open3).to receive(:capture3)
          .with('BUNDLE_GEMFILE=Gemfile.next bundle lock --print --lockfile Gemfile.lock | diff Gemfile.next.lock -')
          .and_return(['diff output', '', failure_status])
      end

      it 'aborts with an error message' do
        expect { run_task }.to abort_execution
          .with_message('inconsistent Gemfile.next.lock detected, run `bundle exec rake bundler:gemfile:sync`')
      end
    end

    context 'when FROM_LEFTHOOK env var is set' do
      before do
        stub_env('FROM_LEFTHOOK', '1')
      end

      it 'suppresses output' do
        run_task
        expect($stdout.string).to be_empty
      end

      context 'when a command fails' do
        before do
          allow(Open3).to receive(:capture3)
            .with('bundle lock --print | diff Gemfile.lock -')
            .and_return(['diff output', 'some error', failure_status])
        end

        it 'suppresses output' do
          expect { run_task }.to abort_execution
          expect($stdout.string).to be_empty
        end
      end
    end
  end
end
