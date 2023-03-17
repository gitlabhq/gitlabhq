# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CompareService, feature_category: :source_code_management do
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

    context 'compare with target branch that does not exist' do
      subject { service.execute(project, 'non-existent-ref') }

      it { expect(subject).to be_nil }
    end

    context 'compare with source branch that does not exist' do
      let(:service) { described_class.new(project, 'non-existent-branch') }

      subject { service.execute(project, 'non-existent-ref') }

      it { expect(subject).to be_nil }
    end
  end
end
