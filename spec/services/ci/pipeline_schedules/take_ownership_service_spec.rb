# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::TakeOwnershipService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, :repository, maintainers: [user, owner], reporters: reporter)
  end

  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: owner) }

  describe '#execute' do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(pipeline_schedule, reporter) }

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(_('Failed to change the owner'))
      end
    end

    context 'when user has permission' do
      subject(:service) { described_class.new(pipeline_schedule, user) }

      it 'returns ServiceResponse.success' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
        expect(result.payload).to eq(pipeline_schedule)
      end

      context 'when schedule update fails' do
        subject(:service) { described_class.new(pipeline_schedule, owner) }

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
          expect(result.message).to eq(['An error occurred'])
        end
      end
    end
  end
end
