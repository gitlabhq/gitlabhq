# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::BulkDeleteRunnersService, '#execute' do
  subject { described_class.new(**service_args).execute }

  let(:service_args) { { runners: runners_arg } }
  let(:runners_arg) { }

  context 'with runners specified' do
    let!(:instance_runner) { create(:ci_runner) }
    let!(:group_runner) { create(:ci_runner, :group) }
    let!(:project_runner) { create(:ci_runner, :project) }

    shared_examples 'a service deleting runners in bulk' do
      it 'destroys runners', :aggregate_failures do
        expect { subject }.to change { Ci::Runner.count }.by(-2)

        is_expected.to eq({ deleted_count: 2, deleted_ids: [instance_runner.id, project_runner.id] })
        expect(instance_runner[:errors]).to be_nil
        expect(project_runner[:errors]).to be_nil
        expect { project_runner.runner_projects.first.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { group_runner.reload }.not_to raise_error
        expect { instance_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { project_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with some runners already deleted' do
        before do
          instance_runner.destroy!
        end

        let(:runners_arg) { [instance_runner.id, project_runner.id] }

        it 'destroys runners and returns only deleted runners', :aggregate_failures do
          expect { subject }.to change { Ci::Runner.count }.by(-1)

          is_expected.to eq({ deleted_count: 1, deleted_ids: [project_runner.id] })
          expect(instance_runner[:errors]).to be_nil
          expect(project_runner[:errors]).to be_nil
          expect { project_runner.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with too many runners specified' do
        before do
          stub_const("#{described_class}::RUNNER_LIMIT", 1)
        end

        it 'deletes only first RUNNER_LIMIT runners' do
          expect { subject }.to change { Ci::Runner.count }.by(-1)

          is_expected.to eq({ deleted_count: 1, deleted_ids: [instance_runner.id] })
        end
      end
    end

    context 'with runners specified as relation' do
      let(:runners_arg) { Ci::Runner.not_group_type }

      include_examples 'a service deleting runners in bulk'
    end

    context 'with runners specified as array of IDs' do
      let(:runners_arg) { Ci::Runner.not_group_type.ids }

      include_examples 'a service deleting runners in bulk'
    end

    context 'with no arguments specified' do
      let(:runners_arg) { nil }

      it 'returns 0 deleted runners' do
        is_expected.to eq({ deleted_count: 0, deleted_ids: [] })
      end
    end
  end
end
