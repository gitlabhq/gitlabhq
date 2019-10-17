# frozen_string_literal: true

require 'spec_helper'

# For easier debugging set `PUMA_DEBUG=1`

describe Gitlab::Cluster::Mixins::PumaCluster do
  PUMA_STARTUP_TIMEOUT = 30

  context 'when running Puma in Cluster-mode' do
    %i[USR1 USR2 INT HUP].each do |signal|
      it "for #{signal} does execute phased restart block" do
        with_puma(workers: 1) do |pid|
          Process.kill(signal, pid)

          child_pid, child_status = Process.wait2(pid)
          expect(child_pid).to eq(pid)
          expect(child_status).to be_exited
          expect(child_status.exitstatus).to eq(140)
        end
      end
    end
  end

  private

  def with_puma(workers:, timeout: PUMA_STARTUP_TIMEOUT)
    with_puma_config(workers: workers) do |puma_rb|
      cmdline = [
        "bundle", "exec", "puma",
        "-C", puma_rb,
        "-I", Rails.root.to_s
      ]

      IO.popen(cmdline) do |process|
        # wait for process to start:
        # [2123] * Listening on tcp://127.0.0.1:0
        wait_for_output(process, /Listening on/, timeout: timeout)
        consume_output(process)

        yield(process.pid)
      ensure
        begin
          Process.kill(:KILL, process.pid)
        rescue Errno::ESRCH
        end
      end
    end
  end

  def with_puma_config(workers:)
    Dir.mktmpdir do |dir|
      File.write "#{dir}/puma.rb", <<-EOF
        require './lib/gitlab/cluster/lifecycle_events'
        require './lib/gitlab/cluster/mixins/puma_cluster'

        workers #{workers}
        bind "tcp://127.0.0.1:0"
        preload_app!

        app -> (env) { [404, {}, ['']] }

        Puma::Cluster.prepend(#{described_class})

        Gitlab::Cluster::LifecycleEvents.on_before_phased_restart do
          exit(140)
        end

        # redirect stderr to stdout
        $stderr.reopen($stdout)
      EOF

      yield("#{dir}/puma.rb")
    end
  end

  def wait_for_output(process, output, timeout:)
    Timeout.timeout(timeout) do
      loop do
        line = process.readline
        puts "PUMA_DEBUG: #{line}" if ENV['PUMA_DEBUG']
        break if line =~ output
      end
    end
  end

  def consume_output(process)
    Thread.new do
      loop do
        line = process.readline
        puts "PUMA_DEBUG: #{line}" if ENV['PUMA_DEBUG']
      end
    rescue
    end
  end
end
