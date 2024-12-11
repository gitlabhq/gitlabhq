# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::UpdateService, feature_category: :continuous_integration do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public, :repository) }
  let_it_be_with_reload(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project_owner) { create(:user) }

  let_it_be(:pipeline_schedule_variable) do
    create(:ci_pipeline_schedule_variable,
      key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule)
  end

  let_it_be_with_reload(:repository) { project.repository }

  before_all do
    project.update!(ci_pipeline_variables_minimum_override_role: :developer)
    project.add_maintainer(user)
    project.add_owner(project_owner)
    project.add_reporter(reporter)
    repository.add_branch(project.creator, 'patch-x', 'master')
    repository.add_branch(project.creator, 'ambiguous', 'master')
    repository.add_branch(project.creator, '1/nested/branch-name', 'master')
    repository.add_tag(project.creator, 'ambiguous', 'master')

    pipeline_schedule.reload
  end

  describe "execute" do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(pipeline_schedule, reporter, {}) }

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)

        error_message = _('The current user is not authorized to update the pipeline schedule')
        expect(result.message).to match_array([error_message])
        expect(pipeline_schedule.errors).to match_array([error_message])
      end
    end

    context 'when user has permission' do
      let(:ref) { 'patch-x' }
      let(:params) do
        {
          description: 'updated_desc',
          ref: ref,
          active: false,
          cron: '*/1 * * * *',
          variables_attributes: [
            { id: pipeline_schedule_variable.id, key: 'bar', secret_value: 'barvalue' }
          ]
        }
      end

      subject(:service) { described_class.new(pipeline_schedule, user, params) }

      it 'updates database values with passed params' do
        expect do
          service.execute
          pipeline_schedule.reload
        end.to change { pipeline_schedule.description }
                 .from('pipeline schedule').to('updated_desc')
                 .and change { pipeline_schedule.ref }
                        .from("#{Gitlab::Git::BRANCH_REF_PREFIX}master")
                        .to("#{Gitlab::Git::BRANCH_REF_PREFIX}patch-x")
                        .and change {
                          pipeline_schedule.active
                        }.from(true).to(false)
                         .and change {
                           pipeline_schedule.cron
                         }.from('0 1 * * *').to('*/1 * * * *')
                          .and change {
                            pipeline_schedule.variables.last.key
                          }.from('foo').to('bar')
                           .and change {
                             pipeline_schedule.variables.last.value
                           }.from('foovalue').to('barvalue')
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

        context 'when the branch name is nested' do
          let(:ref) { '1/nested/branch-name' }

          it 'saves values with passed params' do
            result = service.execute

            expect(result.payload).to have_attributes(
              description: 'updated_desc',
              ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}1/nested/branch-name",
              active: false,
              cron: '*/1 * * * *',
              cron_timezone: 'UTC'
            )
          end
        end
      end

      context 'when the new branch is protected', :request_store do
        let(:maintainer_access) { :no_one_can_merge }

        before do
          create(:protected_branch, :no_one_can_push, maintainer_access, name: 'patch-x', project: project)
        end

        after do
          ProtectedBranches::CacheService.new(project).refresh
        end

        context 'when called by someone other than the schedule owner who can update the ref' do
          let(:maintainer_access) { :maintainers_can_merge }

          subject(:service) { described_class.new(pipeline_schedule, project_owner, params) }

          it 'does not update the schedule' do
            expect do
              service.execute
              pipeline_schedule.reload
            end.not_to change { pipeline_schedule.description }
          end
        end

        context 'when called by the schedule owner' do
          it 'does not update the schedule' do
            expect do
              service.execute
              pipeline_schedule.reload
            end.not_to change { pipeline_schedule.description }
          end

          context 'when the owner can update the ref' do
            let(:maintainer_access) { :maintainers_can_merge }

            it 'updates the schedule' do
              expect { service.execute }.to change { pipeline_schedule.description }
            end
          end
        end
      end

      context 'when creating a variable' do
        let(:params) do
          {
            variables_attributes: [
              { key: 'ABC', secret_value: 'ABC123' }
            ]
          }
        end

        it 'creates the new variable' do
          expect { service.execute }.to change { Ci::PipelineScheduleVariable.count }.by(1)

          expect(pipeline_schedule.variables.last.key).to eq('ABC')
          expect(pipeline_schedule.variables.last.value).to eq('ABC123')
        end
      end

      context 'when deleting a variable' do
        let(:params) do
          {
            variables_attributes: [
              {
                id: pipeline_schedule_variable.id,
                _destroy: true
              }
            ]
          }
        end

        it 'deletes the existing variable' do
          expect { service.execute }.to change { Ci::PipelineScheduleVariable.count }.by(-1)
        end
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
          allow(pipeline_schedule).to receive(:save).and_return(false)

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

    it_behaves_like 'pipeline schedules checking variables permission' do
      subject(:service) { described_class.new(pipeline_schedule, user, params) }
    end
  end
end
