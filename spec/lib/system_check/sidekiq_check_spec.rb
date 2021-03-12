# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::SidekiqCheck do
  describe '#multi_check' do
    def stub_ps_output(output)
      allow(Gitlab::Popen).to receive(:popen).with(%w(ps uxww)).and_return([output, nil])
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

    # TODO: Running without a cluster is deprecated and will be removed in GitLab 14.0
    # https://gitlab.com/gitlab-org/gitlab/-/issues/323225
    context 'when running without a cluster' do
      it 'fails when more than one worker process is running' do
        stub_ps_output <<~PS
          root 2193955 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
          root 2193956 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
        PS

        expect_check_output include(
          'Running? ... yes',
          'Number of Sidekiq processes (cluster/worker) ... 0/2',
          'Please fix the error above and rerun the checks.'
        )
      end

      it 'succeeds when one worker process is running' do
        stub_ps_output <<~PS
          root 2193955 92.2  3.1 4675972 515516 ?      Sl   17:34   0:13 sidekiq 5.2.9 ...
        PS

        expect_check_output <<~OUTPUT
          Running? ... yes
          Number of Sidekiq processes (cluster/worker) ... 0/1
        OUTPUT
      end
    end
  end
end
