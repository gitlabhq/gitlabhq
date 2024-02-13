# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DropPipelinesAndDisableSchedulesForUserService, feature_category: :continuous_integration do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let_it_be(:user_personal_projects) { create_list(:project, 2, :repository, namespace: user.namespace) }

    let_it_be(:group) do
      create(:group) do |group|
        group.add_owner(user)
      end
    end

    let_it_be(:subgroup) { create(:group, parent: group) }

    let_it_be(:other_user) do
      create(:user) do |new_user|
        create(:group_member, :maintainer, user: new_user, group: group)
        create(:group_member, :maintainer, user: new_user, group: subgroup)

        user_personal_projects.each do |project|
          create(:project_member, :maintainer, user: new_user, project: project)
        end
      end
    end

    let_it_be(:group_projects) { create_list(:project, 2, :repository, namespace: group) }
    let_it_be(:subgroup_projects) do
      create_list(:project, 2, :repository, namespace: subgroup)
    end

    let_it_be(:other_user_personal_projects) { create_list(:project, 2, :repository, namespace: other_user.namespace) }

    subject(:service) { described_class.new.execute(user) }

    context 'when user owns pipelines/schedules and groups with other users also owning pipelines/schedules' do
      # Pipelines/pipeline schedules owned by the user in their personal, group and descendent group projects
      let_it_be_with_reload(:user_owned_pipelines) do
        [user_personal_projects, group_projects, subgroup_projects].flat_map do |projects|
          projects.flat_map do |project|
            create_list(:ci_pipeline, 2, :running, project: project, user: user) do |pipeline|
              create(:ci_build, :running, pipeline: pipeline)
              create(:commit_status, :running, pipeline: pipeline)
            end
          end
        end
      end

      let_it_be_with_reload(:user_owned_schedules) do
        [user_personal_projects, group_projects, subgroup_projects].flat_map do |projects|
          projects.flat_map do |project|
            create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: user)
          end
        end
      end

      # Pipelines/pipeline schedules owned by another user in user personal projects and group and descendant group
      # projects owned by the user
      let_it_be_with_reload(:other_user_owned_group_project_pipelines) do
        [user_personal_projects, group_projects, subgroup_projects].flat_map do |projects|
          projects.flat_map do |project|
            create_list(:ci_pipeline, 2, :running, project: project, user: other_user) do |pipeline|
              create(:ci_build, :running, pipeline: pipeline)
              create(:commit_status, :running, pipeline: pipeline)
            end
          end
        end
      end

      let_it_be_with_reload(:other_user_owned_group_project_schedules) do
        [user_personal_projects, group_projects, subgroup_projects].flat_map do |projects|
          projects.flat_map do |project|
            create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: other_user)
          end
        end
      end

      # Pipelines/pipeline schedules owned by another user in their personal projects (should never be changed)
      let_it_be_with_reload(:other_user_owned_personal_pipelines) do
        other_user_personal_projects.flat_map do |project|
          create_list(:ci_pipeline, 2, :running, project: project, user: other_user) do |pipeline|
            create(:ci_build, :running, pipeline: pipeline)
            create(:commit_status, :running, pipeline: pipeline)
          end
        end
      end

      let_it_be_with_reload(:other_user_owned_personal_schedules) do
        other_user_personal_projects.flat_map do |project|
          create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: other_user)
        end
      end

      it 'drops running pipelines/disabled active schedules owned by user', :sidekiq_inline do
        expect { service }.to change {
                                user_owned_pipelines.map(&:reload).map(&:status).uniq
                              }
                              .from(["running"])
                              .to(["failed"])
                          .and change {
                                 user_owned_schedules.map(&:reload).map(&:active?).uniq
                               }
                              .from([true])
                              .to([false])
                          .and not_change {
                                 [
                                   other_user_owned_group_project_pipelines,
                                   other_user_owned_personal_pipelines
                                 ].flatten.map(&:reload).map(&:status).uniq
                               }
                          .and not_change {
                                 [
                                   other_user_owned_group_project_schedules,
                                   other_user_owned_personal_schedules
                                 ].flatten.map(&:reload).map(&:active?).uniq
                               }
      end

      it 'avoids N+1 queries when reading data' do
        control_count = ActiveRecord::QueryRecorder.new do
          described_class.new.execute(user)
        end.count

        extra_projects = create_list(:project, 2, :repository, namespace: group)

        [extra_projects, user_personal_projects, group_projects, subgroup_projects].flat_map do |projects|
          projects.flat_map do |project|
            create_list(:ci_pipeline, 2, :running, project: project, user: user) do |pipeline|
              create(:ci_build, :running, pipeline: pipeline)
              create(:commit_status, :running, pipeline: pipeline)
            end
            create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: user)
          end
        end

        expect do
          described_class.new.execute(user)
        end.not_to exceed_query_limit(control_count)
      end

      context 'when include_owned_projects_and_groups is true' do
        subject(:service) { described_class.new.execute(user, include_owned_projects_and_groups: true) }

        it 'drops running pipelines/disabled active schedules owned by user and/or in their owned groups/descendants',
          :sidekiq_inline do
          expect { service }.to change {
                                  [
                                    user_owned_pipelines,
                                    other_user_owned_group_project_pipelines
                                  ].flatten.map(&:reload).map(&:status).uniq
                                }
                                .from(["running"])
                                .to(["failed"])
                            .and change {
                                   [
                                     user_owned_schedules,
                                     other_user_owned_group_project_schedules
                                   ].flatten.map(&:reload).map(&:active?).uniq
                                 }
                                .from([true])
                                .to([false])
                            .and not_change {
                                   other_user_owned_personal_pipelines.map(&:reload).map(&:active?).uniq
                                 }
                            .and not_change {
                                   other_user_owned_personal_schedules.map(&:reload).map(&:active?).uniq
                                 }
        end

        it 'avoids N+1 queries when reading data' do
          control_count = ActiveRecord::QueryRecorder.new do
            described_class.new.execute(user, include_owned_projects_and_groups: true)
          end.count

          extra_projects = create_list(:project, 2, :repository, namespace: group)

          [user_personal_projects, extra_projects, group_projects, subgroup_projects].flat_map do |projects|
            projects.flat_map do |project|
              create_list(:ci_pipeline, 2, :running, project: project, user: user) do |pipeline|
                create(:ci_build, :running, pipeline: pipeline)
                create(:commit_status, :running, pipeline: pipeline)
              end
              create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: user)
            end
          end

          [extra_projects, group_projects, subgroup_projects].flat_map do |projects|
            projects.flat_map do |project|
              create_list(:ci_pipeline, 2, :running, project: project, user: other_user) do |pipeline|
                create(:ci_build, :running, pipeline: pipeline)
                create(:commit_status, :running, pipeline: pipeline)
              end
              create_list(:ci_pipeline_schedule, 2, active: true, project: project, owner: other_user)
            end
          end

          expect do
            described_class.new.execute(user, include_owned_projects_and_groups: true)
          end.not_to exceed_query_limit(control_count)
        end
      end
    end
  end
end
