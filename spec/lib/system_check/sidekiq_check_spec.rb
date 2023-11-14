# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::SidekiqCheck do
  describe '#multi_check' do
    def stub_ps_output(output)
      allow(Gitlab::Popen).to receive(:popen).with(%w[ps uxww]).and_return([output, nil])
    end

    def expect_check_output(matcher)
      expect { subject.multi_check }.to output(matcher).to_stdout
    end

    it 'fails when no worker processes are running' do
      stub_ps_output <<~PS
        root 2193947  0.9  0.1 146564 18104 ?        Ssl  17:34   0:00 ruby bin/sidekiq-cluster * -P ...
      PS

      expect_check_output include(
        'Running? ... no',
        'Please fix the error above and rerun the checks.'
      )
    end

    it 'fails when more than one cluster process is running' do
      stub_ps_output <<~PS
        root 2193947  0.9  0.1 146564 18104 ?        Ssl  17:34   0:00 ruby bin/sidekiq-cluster * -P ...
        root 2193948  0.9  0.1 146564 18104 ?        Ssl  17:34   0:00 ruby bin/sidekiq-cluster * -P ...
        root 2193955 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
      PS

      expect_check_output include(
        'Running? ... yes',
        'Number of Sidekiq processes (cluster/worker) ... 2/1',
        'Please fix the error above and rerun the checks.'
      )
    end

    context 'when only a worker process is running' do
      before do
        stub_ps_output <<~PS
          root 2193955 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
        PS
      end

      it 'fails with the right message for systemd' do
        allow(File).to receive(:symlink?).with(described_class::SYSTEMD_UNIT_PATH).and_return(true)

        expect_check_output <<~OUTPUT
          Running? ... yes
          Number of Sidekiq processes (cluster/worker) ... 0/1
            Try fixing it:
            sudo systemctl restart gitlab-sidekiq.service
            Please fix the error above and rerun the checks.
        OUTPUT
      end

      it 'fails with the right message for sysvinit' do
        allow(File).to receive(:symlink?).with(described_class::SYSTEMD_UNIT_PATH).and_return(false)
        allow(subject).to receive(:gitlab_user).and_return('git')

        expect_check_output <<~OUTPUT
          Running? ... yes
          Number of Sidekiq processes (cluster/worker) ... 0/1
            Try fixing it:
            sudo service gitlab stop
            sudo pkill -u git -f sidekiq
            sleep 10 && sudo pkill -9 -u git -f sidekiq
            sudo service gitlab start
            Please fix the error above and rerun the checks.
        OUTPUT
      end
    end

    it 'succeeds when one cluster process and one or more worker processes are running' do
      stub_ps_output <<~PS
        root 2193947  0.9  0.1 146564 18104 ?        Ssl  17:34   0:00 ruby bin/sidekiq-cluster * -P ...
        root 2193955 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
        root 2193956 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
      PS

      expect_check_output <<~OUTPUT
        Running? ... yes
        Number of Sidekiq processes (cluster/worker) ... 1/2
      OUTPUT
    end
  end
end
