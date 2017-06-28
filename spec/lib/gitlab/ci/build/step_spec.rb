require 'spec_helper'

describe Gitlab::Ci::Build::Step do
  let(:job) { create(:ci_build, :no_options, commands: "ls -la\ndate") }

  describe '#from_commands' do
    subject { described_class.from_commands(job) }

    it 'fabricates an object' do
      expect(subject.name).to eq(:script)
      expect(subject.script).to eq(['ls -la', 'date'])
      expect(subject.timeout).to eq(job.timeout)
      expect(subject.when).to eq('on_success')
      expect(subject.allow_failure).to be_falsey
    end
  end

  describe '#from_after_script' do
    subject { described_class.from_after_script(job) }

    context 'when after_script is empty' do
      it 'doesn not fabricate an object' do
        is_expected.to be_nil
      end
    end

    context 'when after_script is not empty' do
      let(:job) { create(:ci_build, options: { after_script: ['ls -la', 'date'] }) }

      it 'fabricates an object' do
        expect(subject.name).to eq(:after_script)
        expect(subject.script).to eq(['ls -la', 'date'])
        expect(subject.timeout).to eq(job.timeout)
        expect(subject.when).to eq('always')
        expect(subject.allow_failure).to be_truthy
      end
    end
  end
end
