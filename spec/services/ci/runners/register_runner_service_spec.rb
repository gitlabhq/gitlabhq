# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::RegisterRunnerService, '#execute', :freeze_time, feature_category: :runner do
  let(:registration_token) { 'abcdefg123456' }
  let(:token) {}
  let(:args) { {} }
  let(:runner) { execute.payload[:runner] }

  before do
    stub_application_setting(
      runners_registration_token: registration_token,
      valid_runner_registrars: ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES
    )
  end

  subject(:execute) { described_class.new(token, args).execute }

  shared_examples 'runner registration is disallowed' do
    it 'returns error response with runner_registration_disallowed reason' do
      expect(execute).to be_error
      expect(execute.message).to eq 'runner registration disallowed'
      expect(execute.reason).to eq :runner_registration_disallowed
    end

    it 'does not track runner creation' do
      expect { execute }.not_to trigger_internal_events('create_ci_runner')
    end
  end

  context 'when no token is provided' do
    let(:token) { '' }

    it 'returns error response' do
      expect(execute).to be_error
      expect(execute.message).to eq 'invalid token supplied'
      expect(execute.http_status).to eq :forbidden
    end

    it 'does not track runner creation' do
      expect { execute }.not_to trigger_internal_events('create_ci_runner')
    end
  end

  context 'when invalid token is provided' do
    let(:token) { 'invalid' }

    it 'returns error response' do
      expect(execute).to be_error
      expect(execute.message).to eq 'invalid token supplied'
      expect(execute.http_status).to eq :forbidden
    end

    it 'does not track runner creation' do
      expect { execute }.not_to trigger_internal_events('create_ci_runner')
    end
  end

  context 'when valid token is provided' do
    context 'when instance registration token is used' do
      let(:token) { registration_token }

      it 'creates runner with default values' do
        expect(execute).to be_success

        expect(runner).to be_an_instance_of(::Ci::Runner)
        expect(runner.persisted?).to be_truthy
        expect(runner.run_untagged).to be true
        expect(runner.active).to be true
        expect(runner.token).not_to eq(registration_token)
        expect(runner.token).not_to start_with(::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX)
        expect(runner).to be_instance_type
      end

      it 'tracks internal events', :clean_gitlab_redis_shared_state do
        expect { execute }
          .to trigger_internal_events('create_ci_runner')
          .with(additional_properties: {
            label: 'instance_type',
            property: 'registration_token'
          }).and increment_usage_metrics(
            'counts.count_total_ci_runners_created_with_token'
          )
      end

      context 'when registering instance runners is disallowed' do
        before do
          stub_application_setting(
            allow_runner_registration_token: false,
            runners_registration_token: nil
          )
        end

        it_behaves_like 'runner registration is disallowed'
      end

      context 'with non-default arguments' do
        let(:args) do
          {
            description: 'some description',
            active: false,
            locked: true,
            run_untagged: false,
            tag_list: %w[tag1 tag2],
            access_level: 'ref_protected',
            maximum_timeout: 600,
            name: 'some name'
          }
        end

        it 'creates runner with relevant values', :aggregate_failures do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.active).to eq args[:active]
          expect(runner.locked).to eq args[:locked]
          expect(runner.run_untagged).to eq args[:run_untagged]
          expect(runner.tags).to contain_exactly(
            an_object_having_attributes(name: 'tag1'),
            an_object_having_attributes(name: 'tag2')
          )
          expect(runner.access_level).to eq args[:access_level]
          expect(runner.maximum_timeout).to eq args[:maximum_timeout]
          expect(runner.name).to eq args[:name]

          expect(Ci::Runner.tagged_with('tag1')).to include(runner)
          expect(Ci::Runner.tagged_with('tag2')).to include(runner)
        end

        it 'does not track runner creation with maintenance note' do
          expect { execute }.not_to trigger_internal_events('set_runner_maintenance_note')
        end

        context 'when maintenance note is specified' do
          let(:args) { { maintenance_note: 'a note' } }

          it 'tracks runner creation with maintenance note' do
            expect { execute }
              .to trigger_internal_events('set_runner_maintenance_note')
              .with(additional_properties: { label: 'instance_type' })
          end
        end
      end

      context 'with runner token expiration interval', :freeze_time do
        before do
          stub_application_setting(runner_token_expiration_interval: 5.days)
        end

        it 'creates runner with token expiration' do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.token_expires_at).to eq(5.days.from_now)
        end
      end
    end

    context 'when project registration token is used' do
      let_it_be_with_reload(:project) { create(:project, :allow_runner_registration_token) }

      # Ensure we have a valid token to start with (runners_token is nil when allow_runner_registration_token is false)
      let!(:token) { project.runners_token }
      let(:allow_group_runner_registration_token) { true }

      before do
        project.namespace.update!(allow_runner_registration_token: allow_group_runner_registration_token)
      end

      it 'creates project runner' do
        expect(execute).to be_success

        expect(runner).to be_an_instance_of(::Ci::Runner)
        expect(project.runners.size).to eq(1)
        expect(runner).to eq(project.runners.first)
        expect(runner.token).not_to eq(registration_token)
        expect(runner.token).not_to eq(project.runners_token)
        expect(runner).to be_project_type
      end

      it 'does not track runner creation with maintenance note' do
        expect { execute }.not_to trigger_internal_events('set_runner_maintenance_note')
      end

      it 'tracks internal events', :clean_gitlab_redis_shared_state do
        expect { execute }
          .to trigger_internal_events('create_ci_runner')
          .with(project: project, additional_properties: {
            label: 'project_type',
            property: 'registration_token'
          }).and increment_usage_metrics(
            'redis_hll_counters.count_distinct_project_id_from_create_ci_runner_monthly',
            'redis_hll_counters.count_distinct_project_id_from_create_ci_runner_weekly'
          )
      end

      context 'when maintenance note is specified' do
        let(:args) { { maintenance_note: 'a note' } }

        it 'tracks runner creation with maintenance note' do
          expect { execute }
            .to trigger_internal_events('set_runner_maintenance_note')
            .with(project: project, additional_properties: { label: 'project_type' })
        end
      end

      context 'with runner registration disabled at instance level' do
        before do
          stub_application_setting(
            allow_runner_registration_token: false,
            runners_registration_token: nil
          )
        end

        it_behaves_like 'runner registration is disallowed'
      end

      context 'with runner registration disabled at group level' do
        let(:allow_group_runner_registration_token) { false }

        it_behaves_like 'runner registration is disallowed'
      end

      context 'when it exceeds the application limits' do
        before do
          create(:ci_runner, :project, :online, projects: [project])
          create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
        end

        it 'does not create runner' do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.persisted?).to be_falsey
          expect(runner.errors.messages).to eq(
            'runner_projects.base': ['Maximum number of ci registered project runners (1) exceeded']
          )
          expect(project.runners.reload.size).to eq(1)
        end
      end

      context 'when abandoned runners cause application limits to not be exceeded' do
        before do
          create(:ci_runner, :project, :stale, projects: [project])
          create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
        end

        it 'creates runner' do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.errors).to be_empty
          expect(project.runners.reload.size).to eq(2)
          expect(project.runners.recent.size).to eq(1)
        end
      end

      context 'when valid runner registrars do not include project' do
        before do
          stub_application_setting(valid_runner_registrars: ['group'])
        end

        it 'returns 403 error' do
          expect(execute).to be_error
          expect(execute.http_status).to eq :forbidden
        end
      end
    end

    context 'when group registration token is used' do
      let_it_be_with_reload(:group) { create(:group, :allow_runner_registration_token) }

      # Ensure we have a valid token to start with (runners_token is nil when allow_runner_registration_token is false)
      let!(:token) { group.runners_token }
      let(:allow_group_runner_registration_token) { true }

      before do
        group.update!(allow_runner_registration_token: allow_group_runner_registration_token)
      end

      it 'creates a group runner' do
        expect(execute).to be_success

        expect(runner).to be_an_instance_of(::Ci::Runner)
        expect(runner.errors).to be_empty
        expect(group.runners.reload.size).to eq(1)
        expect(runner.token).not_to eq(registration_token)
        expect(runner.token).not_to eq(group.runners_token)
        expect(runner).to be_group_type
      end

      it 'does not track runner creation with maintenance note' do
        expect { execute }.not_to trigger_internal_events('set_runner_maintenance_note')
      end

      it 'tracks internal events', :clean_gitlab_redis_shared_state do
        expect { execute }
          .to trigger_internal_events('create_ci_runner')
          .with(namespace: group, additional_properties: {
            label: 'group_type',
            property: 'registration_token'
          }).and increment_usage_metrics(
            'redis_hll_counters.count_distinct_namespace_id_from_create_ci_runner_monthly',
            'redis_hll_counters.count_distinct_namespace_id_from_create_ci_runner_weekly'
          )
      end

      context 'when maintenance note is specified' do
        let(:args) { { maintenance_note: 'a note' } }

        it 'tracks runner creation with maintenance note' do
          expect { execute }
            .to trigger_internal_events('set_runner_maintenance_note')
            .with(namespace: group, additional_properties: { label: 'group_type' })
        end
      end

      context 'with runner registration disabled at instance level' do
        before do
          stub_application_setting(
            allow_runner_registration_token: false,
            runners_registration_token: nil
          )
        end

        it_behaves_like 'runner registration is disallowed'
      end

      context 'with runner registration disabled at group level' do
        let(:allow_group_runner_registration_token) { false }

        it_behaves_like 'runner registration is disallowed'
      end

      context 'when it exceeds the application limits' do
        before do
          create(:ci_runner, :unregistered, :created_within_stale_deadline, :group, groups: [group])
          create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
        end

        it 'does not create runner' do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.persisted?).to be_falsey
          expect(runner.errors.messages).to eq(
            'runner_namespaces.base': ['Maximum number of ci registered group runners (1) exceeded']
          )
          expect(group.runners.reload.size).to eq(1)
        end
      end

      context 'when abandoned runners cause application limits to not be exceeded' do
        before do
          create(:ci_runner, :group, :stale, groups: [group])
          create(:ci_runner, :group, :stale, :unregistered, groups: [group])
          create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
        end

        it 'creates runner' do
          expect(execute).to be_success

          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.errors).to be_empty
          expect(group.runners.reload.size).to eq(3)
          expect(group.runners.recent.size).to eq(1)
        end
      end

      context 'when valid runner registrars do not include group' do
        before do
          stub_application_setting(valid_runner_registrars: ['project'])
        end

        it 'returns error response' do
          is_expected.to be_error
        end
      end
    end

    context 'when tags are provided' do
      let(:token) { registration_token }

      let(:args) do
        { tag_list: %w[tag1 tag2] }
      end

      it 'creates runner with tags' do
        expect(runner).to be_persisted

        expect(runner.tags).to contain_exactly(
          an_object_having_attributes(name: 'tag1'),
          an_object_having_attributes(name: 'tag2')
        )
      end

      it 'creates tags in bulk' do
        expect(Gitlab::Ci::Tags::BulkInsert).to receive(:bulk_insert_tags!).and_call_original

        expect(runner).to be_persisted
      end

      context 'and tag list exceeds limit' do
        let(:args) do
          { tag_list: (1..Ci::Runner::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" } }
        end

        it 'does not create any tags' do
          expect(Gitlab::Ci::Tags::BulkInsert).not_to receive(:bulk_insert_tags!)

          expect(runner).not_to be_persisted
          expect(runner.tags).to be_empty
        end
      end
    end
  end
end
