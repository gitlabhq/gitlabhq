# coding: utf-8
require 'spec_helper'

describe Gitlab::Helm do
  let(:namespace) { 'rails-spec' }
  let(:kubeconfig) {}
  let(:logger) {}
  subject { described_class.new(namespace, kubeconfig, logger: logger)}

  def mock_helm_invocation(success:, error: '')
    stderr = StringIO.new(error)
    process_status = double('process_status')
    wait_thr = double('wait_thread')

    expect(Open3).to receive(:popen3).at_least(:once).and_yield(StringIO.new, StringIO.new, stderr, wait_thr)
    expect(wait_thr).to receive(:value).at_least(:once).and_return(process_status)
    expect(process_status).to receive(:success?).at_least(:once).and_return(success)
  end

  shared_examples 'invokes helm binary' do |method, args|
    context 'when helm binary fails' do
      let(:error_text) { 'Something went wrong' }

      before do
        mock_helm_invocation(success: false, error: error_text)
      end

      it 'throws exception' do
        expect { subject.send(method, *args) }.to raise_exception(Gitlab::Helm::Error, error_text)
      end
    end

    context 'when helm binary exit-code is 0' do
      before do
        mock_helm_invocation(success: true)
      end

      it "doesn't raise exceptions" do
        expect { subject.send(method, *args) }.not_to raise_exception
      end
    end
  end

  it { is_expected.to delegate_method(:debug).to(:logger) }
  it { is_expected.to delegate_method(:debug?).to(:logger) }

  describe '#init!' do
    it 'invokes helm init --upgrade' do
      expect(subject).to receive(:helm).with('init', '--upgrade', env: instance_of(Hash))

      subject.init!
    end

    it_should_behave_like 'invokes helm binary', :init!, []
  end

  describe '#install_or_upgrade!' do
    let(:app_name) { 'app_name' }
    let(:chart) { 'stable/a_chart' }

    it 'invokes helm upgrade --install --namespace namespace app_name chart' do
      expect(subject).to receive(:helm).with('init', '--client-only', env: instance_of(Hash)).ordered.once
      expect(subject).to receive(:helm).with('upgrade', '--install', '--namespace', namespace, app_name, chart, env: instance_of(Hash)).ordered.once

      subject.install_or_upgrade!(app_name, chart)
    end

    it_should_behave_like 'invokes helm binary', :install_or_upgrade!, %w[app_name chart]
  end
end
