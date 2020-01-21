# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Build::ResourceGroup do
  let_it_be(:project) { create(:project) }
  let(:job) { build(:ci_build, project: project) }
  let(:seed) { described_class.new(job, resource_group_key) }

  describe '#to_resource' do
    subject { seed.to_resource }

    context 'when resource group key is specified' do
      let(:resource_group_key) { 'iOS' }

      it 'returns a resource group object' do
        is_expected.to be_a(Ci::ResourceGroup)
        expect(subject.key).to eq('iOS')
      end

      context 'when environment has an invalid URL' do
        let(:resource_group_key) { ':::' }

        it 'returns nothing' do
          is_expected.to be_nil
        end
      end

      context 'when there is a resource group already' do
        let!(:resource_group) { create(:ci_resource_group, project: project, key: 'iOS') }

        it 'does not create a new resource group' do
          expect { subject }.not_to change { Ci::ResourceGroup.count }
        end
      end
    end

    context 'when resource group key is nil' do
      let(:resource_group_key) { nil }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end
end
