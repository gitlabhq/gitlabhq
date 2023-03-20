# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Console, feature_category: :application_instrumentation do
  describe '.welcome!' do
    context 'when running in the Rails console' do
      before do
        allow(Gitlab::Runtime).to receive(:console?).and_return(true)
        allow(Gitlab::Metrics::BootTimeTracker.instance).to receive(:startup_time).and_return(42)
      end

      shared_examples 'console messages' do
        it 'prints system info' do
          expect($stdout).to receive(:puts).ordered.with(include("--"))
          expect($stdout).to receive(:puts).ordered.with(include("Ruby:"))
          expect($stdout).to receive(:puts).ordered.with(include("GitLab:"))
          expect($stdout).to receive(:puts).ordered.with(include("GitLab Shell:"))
          expect($stdout).to receive(:puts).ordered.with(include("PostgreSQL:"))
          expect($stdout).to receive(:puts).ordered.with(include("--"))
          expect($stdout).not_to receive(:puts).ordered

          described_class.welcome!
        end
      end

      # This is to add line coverage, not to actually verify behavior on macOS.
      context 'on darwin' do
        before do
          stub_const('RUBY_PLATFORM', 'x86_64-darwin-19')
        end

        it_behaves_like 'console messages'
      end

      it_behaves_like 'console messages'
    end

    context 'when not running in the Rails console' do
      before do
        allow(Gitlab::Runtime).to receive(:console?).and_return(false)
      end

      it 'does not print anything' do
        expect($stdout).not_to receive(:puts)

        described_class.welcome!
      end
    end
  end
end
