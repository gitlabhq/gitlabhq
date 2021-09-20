# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdatePendingBuildService do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }
    let_it_be(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }
    let_it_be(:update_params) { { instance_runners_enabled: true } }

    subject(:service) { described_class.new(model, update_params).execute }

    context 'validations' do
      context 'when model is invalid' do
        let(:model) { pending_build_1 }

        it 'raises an error' do
          expect { service }.to raise_error(described_class::InvalidModelError)
        end
      end

      context 'when params is invalid' do
        let(:model) { group }
        let(:update_params) { { minutes_exceeded: true } }

        it 'raises an error' do
          expect { service }.to raise_error(described_class::InvalidParamsError)
        end
      end
    end

    context 'when model is a group with pending builds' do
      let(:model) { group }

      it 'updates all pending builds', :aggregate_failures do
        service

        expect(pending_build_1.reload.instance_runners_enabled).to be_truthy
        expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
      end

      context 'when ci_pending_builds_maintain_shared_runners_data is disabled' do
        before do
          stub_feature_flags(ci_pending_builds_maintain_shared_runners_data: false)
        end

        it 'does not update all pending builds', :aggregate_failures do
          service

          expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
          expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
        end
      end
    end

    context 'when model is a project with pending builds' do
      let(:model) { project }

      it 'updates all pending builds', :aggregate_failures do
        service

        expect(pending_build_1.reload.instance_runners_enabled).to be_truthy
        expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
      end

      context 'when ci_pending_builds_maintain_shared_runners_data is disabled' do
        before do
          stub_feature_flags(ci_pending_builds_maintain_shared_runners_data: false)
        end

        it 'does not update all pending builds', :aggregate_failures do
          service

          expect(pending_build_1.reload.instance_runners_enabled).to be_falsey
          expect(pending_build_2.reload.instance_runners_enabled).to be_truthy
        end
      end
    end
  end
end
