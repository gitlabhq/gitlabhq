require 'spec_helper'

describe Gitlab::Ci::Build::Step do
  let(:job) { create(:ci_build, :no_options, commands: "ls -la\ndate") }

  describe '#from_commands' do
    subject { described_class.from_commands(job) }

    it { expect(subject.name).to eq(:script) }
    it { expect(subject.script).to eq(['ls -la', 'date']) }
    it { expect(subject.timeout).to eq(job.timeout) }
    it { expect(subject.when).to eq('on_success') }
    it { expect(subject.allow_failure).to be_falsey }
  end

  describe '#from_after_script' do
    subject { described_class.from_after_script(job) }

    context 'when after_script is empty' do
      it { is_expected.to be(nil) }
    end

    context 'when after_script is not empty' do
      let(:job) { create(:ci_build, options: { after_script: "ls -la\ndate" }) }

      it { expect(subject.name).to eq(:after_script) }
      it { expect(subject.script).to eq(['ls -la', 'date']) }
      it { expect(subject.timeout).to eq(job.timeout) }
      it { expect(subject.when).to eq('always') }
      it { expect(subject.allow_failure).to be_truthy }
    end
  end
end
