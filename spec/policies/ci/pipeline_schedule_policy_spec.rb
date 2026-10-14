# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulePolicy, :models, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :repository, create_tag: tag_ref_name) }
  let_it_be_with_refind(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
  let_it_be(:tag_ref_name) { "v1.0.0" }

  subject(:policy) do
    described_class.new(user, pipeline_schedule)
  end

  describe 'rules' do
    describe 'rules for protected ref' do
      context 'for branch' do
        subject(:policy) { described_class.new(user, pipeline_schedule) }

        %w[refs/heads/master master].each do |branch_ref|
          context "with #{branch_ref}" do
            let_it_be(:branch_ref_name) { "master" }
            let_it_be_with_refind(:pipeline_schedule) do
              create(:ci_pipeline_schedule, :nightly, project: project, ref: branch_ref)
            end

            shared_examples_for 'allowed by those who can update the branch' do
              where(:push_access_level, :merge_access_level, :project_role, :allowed) do
                :no_one_can_push | :no_one_can_merge | :owner      | false
                :no_one_can_push | :no_one_can_merge | :maintainer | false
                :no_one_can_push | :no_one_can_merge | :developer  | false
                :no_one_can_push | :no_one_can_merge | :reporter   | false
                :no_one_can_push | :no_one_can_merge | :guest      | false

                :maintainers_can_push | :no_one_can_merge | :owner      | true
                :maintainers_can_push | :no_one_can_merge | :maintainer | true
                :maintainers_can_push | :no_one_can_merge | :developer  | false
                :maintainers_can_push | :no_one_can_merge | :reporter   | false
                :maintainers_can_push | :no_one_can_merge | :guest      | false

                :developers_can_push | :no_one_can_merge |  :owner      | true
                :developers_can_push | :no_one_can_merge |  :maintainer | true
                :developers_can_push | :no_one_can_merge |  :developer  | true
                :developers_can_push | :no_one_can_merge |  :reporter   | false
                :developers_can_push | :no_one_can_merge |  :guest      | false

                :no_one_can_push | :maintainers_can_merge | :owner      | true
                :no_one_can_push | :maintainers_can_merge | :maintainer | true
                :no_one_can_push | :maintainers_can_merge | :developer  | false
                :no_one_can_push | :maintainers_can_merge | :reporter   | false
                :no_one_can_push | :maintainers_can_merge | :guest      | false

                :no_one_can_push | :developers_can_merge | :owner      | true
                :no_one_can_push | :developers_can_merge | :maintainer | true
                :no_one_can_push | :developers_can_merge | :developer  | true
                :no_one_can_push | :developers_can_merge | :reporter   | false
                :no_one_can_push | :developers_can_merge | :guest      | false
              end

              with_them do
                before do
                  create(:protected_branch, push_access_level, merge_access_level, name: branch_ref_name,
                    project: project)
                  project.add_role(user, project_role)
                end

                it { allowed ? expect_allowed(ability_name) : expect_disallowed(ability_name) }
              end
            end

            shared_examples_for 'only allowed by schedule owners who can update the branch' do
              where(:push_access_level, :merge_access_level, :schedule_owner, :project_role, :allowed) do
                :no_one_can_push | :no_one_can_merge  | :other_user | :owner      | false
                :no_one_can_push | :no_one_can_merge  | :user       | :owner      | false
                :no_one_can_push | :no_one_can_merge  | :user       | :maintainer | false
                :no_one_can_push | :no_one_can_merge  | :user       | :developer  | false
                :no_one_can_push | :no_one_can_merge  | :user       | :reporter   | false
                :no_one_can_push | :no_one_can_merge  | :user       | :guest      | false

                :maintainers_can_push | :no_one_can_merge | :other_user | :owner      | false
                :maintainers_can_push | :no_one_can_merge | :user       | :owner      | true
                :maintainers_can_push | :no_one_can_merge | :user       | :maintainer | true
                :maintainers_can_push | :no_one_can_merge | :user       | :developer  | false
                :maintainers_can_push | :no_one_can_merge | :user       | :reporter   | false
                :maintainers_can_push | :no_one_can_merge | :user       | :guest      | false

                :developers_can_push | :no_one_can_merge | :other_user | :owner      | false
                :developers_can_push | :no_one_can_merge | :user       | :owner      | true
                :developers_can_push | :no_one_can_merge | :user       | :maintainer | true
                :developers_can_push | :no_one_can_merge | :user       | :developer  | true
                :developers_can_push | :no_one_can_merge | :user       | :reporter   | false
                :developers_can_push | :no_one_can_merge | :user       | :guest      | false

                :no_one_can_push | :maintainers_can_merge | :other_user | :owner      | false
                :no_one_can_push | :maintainers_can_merge | :user       | :owner      | true
                :no_one_can_push | :maintainers_can_merge | :user       | :maintainer | true
                :no_one_can_push | :maintainers_can_merge | :user       | :developer  | false
                :no_one_can_push | :maintainers_can_merge | :user       | :reporter   | false
                :no_one_can_push | :maintainers_can_merge | :user       | :guest      | false

                :no_one_can_push | :developers_can_merge | :other_user | :owner      | false
                :no_one_can_push | :developers_can_merge | :user       | :owner      | true
                :no_one_can_push | :developers_can_merge | :user       | :maintainer | true
                :no_one_can_push | :developers_can_merge | :user       | :developer  | true
                :no_one_can_push | :developers_can_merge | :user       | :reporter   | false
                :no_one_can_push | :developers_can_merge | :user       | :guest      | false
              end

              with_them do
                before do
                  create(:protected_branch, push_access_level, merge_access_level, name: branch_ref_name,
                    project: project)
                  project.add_role(user, project_role)
                  project.add_role(other_user, project_role)

                  pipeline_schedule.owner = schedule_owner == :user ? user : other_user
                end

                it { allowed ? expect_allowed(ability_name) : expect_disallowed(ability_name) }
              end
            end

            describe 'create_pipeline_schedule' do
              let(:ability_name) { :create_pipeline_schedule }
              let(:pipeline_schedule) { project.pipeline_schedules.new(ref: branch_ref) }

              it_behaves_like 'allowed by those who can update the branch'
            end

            describe 'play_pipeline_schedule' do
              let(:ability_name) { :play_pipeline_schedule }

              it_behaves_like 'allowed by those who can update the branch'
            end

            describe 'update_pipeline_schedule' do
              let(:ability_name) { :update_pipeline_schedule }

              it_behaves_like 'only allowed by schedule owners who can update the branch'
            end
          end
        end
      end

      context 'for tag' do
        %w[refs/tags/v1.0.0 v1.0.0].each do |tag_ref|
          context "with #{tag_ref}" do
            let_it_be_with_refind(:pipeline_schedule) do
              create(:ci_pipeline_schedule, :nightly, project: project, ref: tag_ref)
            end

            subject(:policy) { described_class.new(user, pipeline_schedule) }

            shared_examples_for 'allowed by those who can update the tag' do
              where(:access_level, :project_role, :allowed) do
                :no_one_can_create | :owner      | false
                :no_one_can_create | :maintainer | false
                :no_one_can_create | :developer  | false
                :no_one_can_create | :reporter   | false
                :no_one_can_create | :guest      | false

                :maintainers_can_create | :owner      | true
                :maintainers_can_create | :maintainer | true
                :maintainers_can_create | :developer  | false
                :maintainers_can_create | :reporter   | false
                :maintainers_can_create | :guest      | false

                :developers_can_create | :owner      | true
                :developers_can_create | :maintainer | true
                :developers_can_create | :developer  | true
                :developers_can_create | :reporter   | false
                :developers_can_create | :guest      | false
              end

              with_them do
                before do
                  create(:protected_tag, access_level, name: tag_ref_name, project: project)
                  project.add_role(user, project_role)
                end

                it { allowed ? expect_allowed(ability_name) : expect_disallowed(ability_name) }
              end
            end

            shared_examples_for 'only allowed by schedule owners who can update the tag' do
              where(:access_level, :schedule_owner, :project_role, :allowed) do
                :no_one_can_create | :other_user | :owner      | false
                :no_one_can_create | :user       | :owner      | false
                :no_one_can_create | :user       | :maintainer | false
                :no_one_can_create | :user       | :developer  | false
                :no_one_can_create | :user       | :reporter   | false
                :no_one_can_create | :user       | :guest      | false

                :maintainers_can_create | :other_user | :owner      | false
                :maintainers_can_create | :user       | :owner      | true
                :maintainers_can_create | :user       | :maintainer | true
                :maintainers_can_create | :user       | :developer  | false
                :maintainers_can_create | :user       | :reporter   | false
                :maintainers_can_create | :user       | :guest      | false

                :developers_can_create | :other_user | :owner      | false
                :developers_can_create | :user       | :owner      | true
                :developers_can_create | :user       | :maintainer | true
                :developers_can_create | :user       | :developer  | true
                :developers_can_create | :user       | :reporter   | false
                :developers_can_create | :user       | :guest      | false
              end

              with_them do
                before do
                  create(:protected_tag, access_level, name: tag_ref_name, project: project)
                  project.add_role(user, project_role)
                  project.add_role(other_user, project_role)

                  pipeline_schedule.owner = schedule_owner == :user ? user : other_user
                end

                it { allowed ? expect_allowed(ability_name) : expect_disallowed(ability_name) }
              end
            end

            describe 'create_pipeline_schedule' do
              let(:ability_name) { :create_pipeline_schedule }
              let(:pipeline_schedule) { project.pipeline_schedules.new(ref: tag_ref) }

              it_behaves_like 'allowed by those who can update the tag'
            end

            describe 'play_pipeline_schedule' do
              let(:ability_name) { :play_pipeline_schedule }

              it_behaves_like 'allowed by those who can update the tag'
            end

            describe 'update_pipeline_schedule' do
              let(:ability_name) { :update_pipeline_schedule }

              it_behaves_like 'only allowed by schedule owners who can update the tag'
            end
          end
        end
      end
    end

    describe 'rules for owner of schedule' do
      before do
        project.add_developer(user)
        pipeline_schedule.update!(owner: user)
      end

      it 'includes abilities to do all operations on pipeline schedule' do
        expect_allowed(:play_pipeline_schedule, :update_pipeline_schedule, :admin_pipeline_schedule)
      end

      it 'allows reading schedule variables and inputs' do
        expect_allowed(:read_pipeline_schedule_variables, :read_pipeline_schedule_inputs)
      end
    end

    describe 'rules for a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'allows for playing and destroying a pipeline schedule' do
        expect_allowed(:play_pipeline_schedule, :admin_pipeline_schedule)
      end

      it 'does not allow for updating of an existing schedule' do
        expect_disallowed(:update_pipeline_schedule)
      end

      it 'allows reading schedule variables and inputs' do
        expect_allowed(:read_pipeline_schedule_variables, :read_pipeline_schedule_inputs)
      end
    end

    describe 'rules for non-owner of schedule' do
      let(:owner) { create(:user) }

      before do
        project.add_maintainer(owner)
        project.add_maintainer(user)
        pipeline_schedule.update!(owner: owner)
      end

      it 'includes abilities to take ownership' do
        expect_allowed(:admin_pipeline_schedule)
      end
    end

    describe 'rules for developer (non-owner)' do
      before do
        project.add_developer(user)
      end

      it 'does not allow reading schedule variables or inputs' do
        expect_disallowed(:read_pipeline_schedule_variables, :read_pipeline_schedule_inputs)
      end
    end

    describe 'rules for unauthenticated user' do
      let(:user) { nil }

      it 'does not allow reading schedule variables or inputs' do
        expect_disallowed(:read_pipeline_schedule_variables, :read_pipeline_schedule_inputs)
      end
    end
  end
end
