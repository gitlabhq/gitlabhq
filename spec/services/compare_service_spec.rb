require 'spec_helper'

describe CompareService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, 'feature') }

  describe '#execute' do
    context 'compare with base, like feature...fix' do
      subject { service.execute(project, 'fix', straight: false) }

      it { expect(subject.diffs.size).to eq(1) }
    end

    context 'straight compare, like feature..fix' do
      subject { service.execute(project, 'fix', straight: true) }

      it { expect(subject.diffs.size).to eq(3) }
    end
  end
end
