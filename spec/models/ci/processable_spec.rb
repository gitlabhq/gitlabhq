# frozen_string_literal: true

require 'spec_helper'

describe Ci::Processable do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

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

  describe 'validate presence of scheduling_type' do
    context 'on create' do
      let(:processable) do
        build(
          :ci_build, :created, project: project, pipeline: pipeline,
          importing: importing, scheduling_type: nil
        )
      end

      context 'when importing' do
        let(:importing) { true }

        context 'when validate_scheduling_type_of_processables is true' do
          before do
            stub_feature_flags(validate_scheduling_type_of_processables: true)
          end

          it 'does not validate' do
            expect(processable).to be_valid
          end
        end

        context 'when validate_scheduling_type_of_processables is false' do
          before do
            stub_feature_flags(validate_scheduling_type_of_processables: false)
          end

          it 'does not validate' do
            expect(processable).to be_valid
          end
        end
      end

      context 'when not importing' do
        let(:importing) { false }

        context 'when validate_scheduling_type_of_processables is true' do
          before do
            stub_feature_flags(validate_scheduling_type_of_processables: true)
          end

          it 'validates' do
            expect(processable).not_to be_valid
          end
        end

        context 'when validate_scheduling_type_of_processables is false' do
          before do
            stub_feature_flags(validate_scheduling_type_of_processables: false)
          end

          it 'does not validate' do
            expect(processable).to be_valid
          end
        end
      end
    end

    context 'on update' do
      let(:processable) { create(:ci_build, :created, project: project, pipeline: pipeline) }

      it 'does not validate' do
        processable.scheduling_type = nil
        expect(processable).to be_valid
      end
    end
  end
end
