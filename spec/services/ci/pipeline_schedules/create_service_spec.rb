# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::CreateService, feature_category: :continuous_integration do
  let_it_be(:reporter) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, :repository, maintainers: user, reporters: reporter) }
  let_it_be_with_reload(:repository) { project.repository }

  subject(:service) { described_class.new(project, user, params) }

  before do
    stub_feature_flags(enforce_full_refs_for_pipeline_schedules: false)
  end

  describe "execute" do
    before_all do
      repository.add_branch(project.creator, 'patch-x', 'master')
    end

    context 'when user does not have permission' do
      subject(:service) { described_class.new(project, reporter, {}) }

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)

        error_message = _('The current user is not authorized to create the pipeline schedule')
        expect(result.message).to match_array([error_message])
        expect(result.payload.errors).to match_array([error_message])
      end
    end

    context 'when user has permission' do
      let(:params) do
        {
          description: 'desc',
          ref: 'patch-x',
          active: false,
          cron: '*/1 * * * *',
          cron_timezone: 'UTC'
        }
      end

      subject(:service) { described_class.new(project, user, params) }

      context 'when enforce_full_refs_for_pipeline_schedules is enabled' do
        before do
          stub_feature_flags(enforce_full_refs_for_pipeline_schedules: true)
        end

        it 'saves values with passed params' do
          result = service.execute

          expect(result.payload).to have_attributes(
            description: 'desc',
            ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}patch-x",
            active: false,
            cron: '*/1 * * * *',
            cron_timezone: 'UTC'
          )
        end
      end

      it 'saves values with passed params' do
        result = service.execute

        expect(result.payload).to have_attributes(
          description: 'desc',
          ref: "patch-x",
          active: false,
          cron: '*/1 * * * *',
          cron_timezone: 'UTC'
        )
      end

      it 'returns ServiceResponse.success' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end

      context 'when schedule save fails' do
        subject(:service) { described_class.new(project, user, {}) }

        before do
          errors = ActiveModel::Errors.new(project)
          errors.add(:base, 'An error occurred')

          allow_next_instance_of(Ci::PipelineSchedule) do |instance|
            allow(instance).to receive(:save).and_return(false)
            allow(instance).to receive(:errors).and_return(errors)
          end
        end

        it 'returns ServiceResponse.error' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to match_array(['An error occurred'])
        end
      end
    end

    it_behaves_like 'pipeline schedules checking variables permission'
  end
end
