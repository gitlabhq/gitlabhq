# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Processable::ResourceGroup do
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

      context 'when creating a new resource group' do
        it 'uses the default process mode from project settings' do
          expect(subject.process_mode).to eq('unordered')
        end

        context 'when project has a custom default process mode' do
          before do
            project.ci_cd_settings.update!(resource_group_default_process_mode: 'oldest_first')
          end

          it 'uses the custom default process mode' do
            expect(subject.process_mode).to eq('oldest_first')
          end
        end

        context 'when project has different process modes' do
          where(:project_mode, :expected_mode) do
            [
              %w[unordered unordered],
              %w[oldest_first oldest_first],
              %w[newest_first newest_first],
              %w[newest_ready_first newest_ready_first]
            ]
          end

          with_them do
            before do
              project.ci_cd_settings.update!(resource_group_default_process_mode: project_mode)
            end

            it "creates resource group with #{params[:expected_mode]} process mode" do
              expect(subject.process_mode).to eq(expected_mode)
            end
          end
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
