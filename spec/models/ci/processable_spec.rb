# frozen_string_literal: true

require 'spec_helper'

describe Ci::Processable do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#aggregated_needs_names' do
    let(:with_aggregated_needs) { pipeline.processables.select_with_aggregated_needs(project) }

    context 'with created status' do
      let!(:processable) { create(:ci_build, :created, project: project, pipeline: pipeline) }

      context 'with needs' do
        before do
          create(:ci_build_need, build: processable, name: 'test1')
          create(:ci_build_need, build: processable, name: 'test2')
        end

        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns all needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to contain_exactly('test1', 'test2')
        end

        context 'with ci_dag_support disabled' do
          before do
            stub_feature_flags(ci_dag_support: false)
          end

          it 'returns all processables' do
            expect(with_aggregated_needs).to contain_exactly(processable)
          end

          it 'returns empty needs' do
            expect(with_aggregated_needs.first.aggregated_needs_names).to be_nil
          end
        end
      end

      context 'without needs' do
        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns empty needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to be_nil
        end
      end
    end
  end
end
