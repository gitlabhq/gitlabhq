# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdatePendingBuildService, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be_with_reload(:pending_build_1) { create(:ci_pending_build, project: project, instance_runners_enabled: false) }
  let_it_be_with_reload(:pending_build_2) { create(:ci_pending_build, project: project, instance_runners_enabled: true) }
  let_it_be(:update_params) { { instance_runners_enabled: true } }

  let(:service) { described_class.new(model, update_params) }

  describe '#execute' do
    subject(:update_pending_builds) { service.execute }

    context 'validations' do
      context 'when model is invalid' do
        let(:model) { pending_build_1 }

        it 'raises an error' do
          expect { update_pending_builds }.to raise_error(described_class::InvalidModelError)
        end
      end

      context 'when params is invalid' do
        let(:model) { group }
        let(:update_params) { { minutes_exceeded: true } }

        it 'raises an error' do
          expect { update_pending_builds }.to raise_error(described_class::InvalidParamsError)
        end
      end
    end

    context 'when model is a group with pending builds' do
      let(:model) { group }

      it 'updates all pending builds', :aggregate_failures do
        update_pending_builds

        expect(pending_build_1.instance_runners_enabled).to be_truthy
        expect(pending_build_2.instance_runners_enabled).to be_truthy
      end
    end

    context 'when model is a project with pending builds' do
      let(:model) { project }

      it 'updates all pending builds', :aggregate_failures do
        update_pending_builds

        expect(pending_build_1.instance_runners_enabled).to be_truthy
        expect(pending_build_2.instance_runners_enabled).to be_truthy
      end
    end
  end
end
