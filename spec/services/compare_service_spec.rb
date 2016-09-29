require 'spec_helper'

describe CompareService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { described_class.new }

  describe '#execute' do
    context 'compare with base, like feature...fix' do
      subject { service.execute(project, 'feature', project, 'fix', false) }

      it { expect(subject.diffs.size).to eq(1) }
    end

    context 'straight compare, like feature..fix' do
      subject { service.execute(project, 'feature', project, 'fix', true) }

      it { expect(subject.diffs.size).to eq(3) }
    end
  end
end
