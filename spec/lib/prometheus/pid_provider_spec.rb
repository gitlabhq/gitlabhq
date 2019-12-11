# frozen_string_literal: true

require 'fast_spec_helper'

describe Prometheus::PidProvider do
  describe '.worker_id' do
    subject { described_class.worker_id }

    before do
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(false)
    end

    context 'when running in Sidekiq server mode' do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      context 'in a clustered setup' do
        before do
          stub_env('SIDEKIQ_WORKER_ID', '123')
        end

        it { is_expected.to eq 'sidekiq_123' }
      end

      context 'in a single process setup' do
        it { is_expected.to eq 'sidekiq' }
      end
    end

    context 'when running in Unicorn mode' do
      before do
        allow(Gitlab::Runtime).to receive(:unicorn?).and_return(true)

        expect(described_class).to receive(:process_name)
          .at_least(:once)
          .and_return(process_name)
      end

      context 'when unicorn master is specified in process name' do
        context 'when running in Omnibus' do
          context 'before the process was renamed' do
            let(:process_name) { "/opt/gitlab/embedded/bin/unicorn"}

            it { is_expected.to eq 'unicorn_master' }
          end

          context 'after the process was renamed' do
            let(:process_name) { "unicorn master -D -E production -c /var/opt/gitlab/gitlab-rails/etc/unicorn.rb /opt/gitlab/embedded/service/gitlab-rails/config.ru" }

            it { is_expected.to eq 'unicorn_master' }
          end
        end

        context 'when in development env' do
          context 'before the process was renamed' do
            let(:process_name) { "path_to_bindir/bin/unicorn_rails"}

            it { is_expected.to eq 'unicorn_master' }
          end

          context 'after the process was renamed' do
            let(:process_name) { "unicorn_rails master -c /gitlab_dir/config/unicorn.rb -E development" }

            it { is_expected.to eq 'unicorn_master' }
          end
        end
      end

      context 'when unicorn worker id is specified in process name' do
        context 'when running in Omnibus' do
          let(:process_name) { "unicorn worker[1] -D -E production -c /var/opt/gitlab/gitlab-rails/etc/unicorn.rb /opt/gitlab/embedded/service/gitlab-rails/config.ru" }

          it { is_expected.to eq 'unicorn_1' }
        end

        context 'when in development env' do
          let(:process_name) { "unicorn_rails worker[1] -c gitlab_dir/config/unicorn.rb -E development" }

          it { is_expected.to eq 'unicorn_1' }
        end
      end

      context 'when no specified unicorn master or worker id in process name' do
        let(:process_name) { "bin/unknown_process"}

        it { is_expected.to eq "process_#{Process.pid}" }
      end
    end

    context 'when running in Puma mode' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)

        expect(described_class).to receive(:process_name)
          .at_least(:once)
          .and_return(process_name)
      end

      context 'when cluster worker id is specified in process name' do
        let(:process_name) { 'puma: cluster worker 1: 17483 [gitlab-puma-worker]' }

        it { is_expected.to eq 'puma_1' }
      end

      context 'when no worker id is specified in process name' do
        let(:process_name) { 'bin/puma' }

        it { is_expected.to eq 'puma_master' }
      end
    end

    context 'when running in unknown mode' do
      it { is_expected.to eq "process_#{Process.pid}" }
    end
  end
end
