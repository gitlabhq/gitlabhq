# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::UpdateService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

  before_all do
    project.add_maintainer(user)
    project.add_reporter(reporter)
  end

  describe "execute" do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(pipeline_schedule, reporter, {}) }

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(_('The current user is not authorized to update the pipeline schedule'))
      end
    end

    context 'when user has permission' do
      let(:params) do
        {
          description: 'updated_desc',
          ref: 'patch-x',
          active: false,
          cron: '*/1 * * * *'
        }
      end

      subject(:service) { described_class.new(pipeline_schedule, user, params) }

      it 'updates database values with passed params' do
        expect { service.execute }
          .to change { pipeline_schedule.description }.from('pipeline schedule').to('updated_desc')
          .and change { pipeline_schedule.ref }.from('master').to('patch-x')
          .and change { pipeline_schedule.active }.from(true).to(false)
          .and change { pipeline_schedule.cron }.from('0 1 * * *').to('*/1 * * * *')
      end

      it 'returns ServiceResponse.success' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
        expect(result.payload.description).to eq('updated_desc')
      end

      context 'when schedule update fails' do
        subject(:service) { described_class.new(pipeline_schedule, user, {}) }

        before do
          allow(pipeline_schedule).to receive(:update).and_return(false)

          errors = ActiveModel::Errors.new(pipeline_schedule)
          errors.add(:base, 'An error occurred')
          allow(pipeline_schedule).to receive(:errors).and_return(errors)
        end

        it 'returns ServiceResponse.error' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to match_array(['An error occurred'])
        end
      end
    end
  end
end
