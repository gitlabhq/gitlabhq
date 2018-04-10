require 'spec_helper'

describe Gitlab::Ci::Status::Build::Empty do
  let(:build) { create(:ci_build, :running) }
  let(:status) { double('core status') }
  let(:user) { double('user') }

  subject { described_class.new(status) }

  describe '#illustration' do
    it 'provides an empty state illustration' do
      expect(subject.illustration).not_to be_empty
    end
  end

  describe '.matches?' do
    subject { described_class.matches?(build, user) }

    context 'when a build has trace' do
      let(:build) { create(:ci_build, :trace_artifact) }

      it { is_expected.to be_falsy }
    end

    context 'with a build that has not been retried' do
      let(:build) { create(:ci_build, :running) }

      it { is_expected.to be_truthy }
    end
  end
end
