# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::CreateService, feature_category: :continuous_integration do
  let_it_be(:reporter) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, :repository, maintainers: user, reporters: reporter) }
  let_it_be_with_reload(:repository) { project.repository }

  subject(:service) { described_class.new(project, user, params) }

  describe "execute" do
    before_all do
      project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      repository.add_branch(project.creator, 'patch-x', 'master')
      repository.add_branch(project.creator, 'ambiguous', 'master')
      repository.add_branch(project.creator, '1/nested/branch-name', 'master')
      repository.add_tag(project.creator, 'ambiguous', 'master')
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
      let(:ref) { 'patch-x' }
      let(:params) do
        {
          description: 'desc',
          ref: ref,
          active: false,
          cron: '*/1 * * * *',
          cron_timezone: 'UTC'
        }
      end

      subject(:service) { described_class.new(project, user, params) }

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

      it 'returns ServiceResponse.success' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end

      context 'when the ref is ambiguous' do
        let(:ref) { 'ambiguous' }

        it 'returns ambiguous ref error' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to match_array(['Ref is ambiguous'])
          expect(result.payload.errors.full_messages).to match_array(['Ref is ambiguous'])
        end
      end

      context 'when the branch name is nested' do
        let(:ref) { '1/nested/branch-name' }

        it 'saves values with passed params' do
          result = service.execute

          expect(result.payload).to have_attributes(
            description: 'desc',
            ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}1/nested/branch-name",
            active: false,
            cron: '*/1 * * * *',
            cron_timezone: 'UTC'
          )
        end
      end

      context 'when schedule save fails' do
        # The ref validation happens on a service level, so it needs to pass to get to the model validation
        subject(:service) { described_class.new(project, user, { ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}master" }) }

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
