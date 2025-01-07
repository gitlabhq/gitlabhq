# frozen_string_literal: true

RSpec.shared_context 'simple_check' do |metrics_prefix, check_name, success_result|
  describe '#metrics' do
    subject { described_class.metrics }

    context 'Check is passing' do
      before do
        allow(described_class).to receive(:check).and_return success_result
      end

      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_success", value: 1)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_timeout", value: 0)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_latency_seconds", value: be >= 0)) }
    end

    context 'Check is misbehaving' do
      before do
        allow(described_class).to receive(:check).and_return 'error!'
      end

      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_success", value: 0)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_timeout", value: 0)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_latency_seconds", value: be >= 0)) }
    end

    context 'Check is timeouting' do
      before do
        allow(described_class).to receive(:check).and_return Timeout::Error.new
      end

      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_success", value: 0)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_timeout", value: 1)) }
      it { is_expected.to include(have_attributes(name: "#{metrics_prefix}_latency_seconds", value: be >= 0)) }
    end
  end

  describe '#readiness' do
    subject { described_class.readiness }

    context 'Check returns ok' do
      before do
        allow(described_class).to receive(:check).and_return success_result
      end

      it { is_expected.to have_attributes(success: true) }
    end

    context 'Check is misbehaving' do
      before do
        allow(described_class).to receive(:check).and_return 'error!'
      end

      it { is_expected.to have_attributes(success: false, message: "unexpected #{described_class.human_name} check result: error!") }
    end

    context 'Check is timeouting' do
      before do
        allow(described_class).to receive(:check).and_return Timeout::Error.new
      end

      it { is_expected.to have_attributes(success: false, message: "#{described_class.human_name} check timed out") }
    end

    context 'Check is raising an unhandled exception' do
      before do
        allow(described_class).to receive(:check).and_raise "unexpected error"
      end

      it { is_expected.to have_attributes(success: false, message: "unexpected #{described_class.human_name} check result: unexpected error") }
    end
  end
end
