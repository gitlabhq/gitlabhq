# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../danger/plugins/project_helper'

RSpec.describe Tooling::Danger::ProjectHelper, feature_category: :tooling do
  include StubENV
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_helper) { Danger::Helper.new(project_helper) }

  subject(:project_helper) { fake_danger.new(git: fake_git) }

  before do
    allow(project_helper).to receive(:helper).and_return(fake_helper)
    allow(fake_helper).to receive(:config).and_return(double(files_to_category: described_class::CATEGORIES))
  end

  describe '#categories_for_file' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(fake_git).to receive(:diff_for_file).with(instance_of(String)) { double(:diff, patch: "+ count(User.active)") }
    end

    where(:path, :expected_categories) do
      'doc/api/graphql/reference/_index.md'              | [:docs, :backend]
      'doc/api/graphql/reference/some_other_file.txt'    | [:docs, :backend]
      'doc/api/openapi/openapi.yaml'                     | [:docs, :backend]
      'doc/api/openapi/any_other_file.yaml'              | [:docs, :backend]

      'config/feature_flags/flag_config.yml' | [:feature_flag]
      'config/feature_flags/nested/flag_config.yaml' | [:feature_flag]
      'ee/config/feature_flags/flag_config.yml' | [:feature_flag]
      'ee/config/feature_flags/nested/flag_config.yaml' | [:feature_flag]
      'jh/config/feature_flags/flag_config.yml' | [:feature_flag]
      'jh/config/feature_flags/nested/flag_config.yaml' | [:feature_flag]
      'config/feature_flags/flag_config.patch' | [:backend]
      'config/feature_flags/nested/flag_config.patch' | [:backend]
      'ee/config/feature_flags/flag_config.patch' | [:backend]
      'ee/config/feature_flags/nested/flag_config.patch' | [:backend]
      'jh/config/feature_flags/flag_config.patch' | [:backend]
      'jh/config/feature_flags/nested/flag_config.patch' | [:backend]

      'usage_data.rb'   | [:database, :backend, :analytics_instrumentation]
      'doc/foo.md'      | [:docs]
      'CONTRIBUTING.md' | [:docs]
      'LICENSE'         | [:docs]
      'MAINTENANCE.md'  | [:docs]
      'PHILOSOPHY.md'   | [:docs]
      'PROCESS.md'      | [:docs]
      'README.md'       | [:docs]

      'ee/doc/foo'      | [:none]
      'ee/README'       | [:none]

      'app/assets/foo'                   | [:frontend]
      'app/views/foo'                    | [:frontend, :backend]
      'public/foo'                       | [:frontend]
      'scripts/frontend/foo'             | [:frontend]
      'spec/frontend/bar'                | [:frontend]
      'spec/frontend_integration/bar'    | [:frontend]
      'vendor/assets/foo'                | [:frontend]
      'babel.config.js'                  | [:frontend]
      'jest.config.js'                   | [:frontend]
      'package.json'                     | [:frontend]
      'yarn.lock'                        | [:frontend]
      'config/foo.js'                    | [:frontend]
      'config/deep/foo.js'               | [:frontend]

      'app/components/pajamas/empty_state_component.html.haml'    | [:frontend, :backend]
      'ee/app/components/pajamas/empty_state_component.html.haml' | [:frontend, :backend]
      'app/components/diffs/overflow_warning_component.html.haml' | [:frontend, :backend]
      'app/components/layouts/horizontal_section_component.rb'    | [:frontend, :backend]

      'ee/app/assets/foo'                | [:frontend]
      'ee/app/views/foo'                 | [:frontend, :backend]
      'ee/spec/frontend/bar'             | [:frontend]
      'ee/spec/frontend_integration/bar' | [:frontend]

      'app/models/foo'             | [:backend]
      'bin/foo'                    | [:backend]
      'config/foo'                 | [:backend]
      'lib/foo'                    | [:backend]
      'rubocop/foo'                | [:backend]
      '.rubocop.yml'               | [:backend]
      '.rubocop_todo.yml'          | [:backend]
      '.rubocop_todo/cop/name.yml' | [:backend]
      'gems/foo/.rubocop.yml'      | [:backend]
      'spec/foo'                   | [:backend]
      'spec/foo/bar'               | [:backend]

      'ee/app/foo'      | [:backend]
      'ee/bin/foo'      | [:backend]
      'ee/spec/foo'     | [:backend]
      'ee/spec/foo/bar' | [:backend]

      'spec/migrations/foo'    | [:database]
      'ee/spec/migrations/foo' | [:database]

      'spec/features/foo'                            | [:test]
      'ee/spec/features/foo'                         | [:test]
      'spec/support/shared_examples/features/foo'    | [:test]
      'ee/spec/support/shared_examples/features/foo' | [:test]
      'spec/support/shared_contexts/features/foo'    | [:test]
      'ee/spec/support/shared_contexts/features/foo' | [:test]
      'spec/support/helpers/features/foo'            | [:test]
      'ee/spec/support/helpers/features/foo'         | [:test]

      'generator_templates/foo' | [:backend]
      'vendor/languages.yml'    | [:backend]
      'file_hooks/examples/'    | [:backend]

      'Gemfile'          | [:backend]
      'Gemfile.lock'     | [:backend]
      'Gemfile.checksum' | [:backend]
      'Rakefile'         | [:backend]
      'FOO_VERSION'      | [:backend]

      'lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'   | [:ci_template]
      'lib/gitlab/ci/templates/dotNET-Core.yml'               | [:ci_template]

      'ee/FOO_VERSION' | [:none]

      'db/schema.rb'                                                                   | [:database]
      'db/structure.sql'                                                               | [:database]
      'db/docs/example.yml'                                                            | [:database]
      'db/migrate/foo'                                                                 | [:database]
      'db/post_migrate/foo'                                                            | [:database]
      'ee/db/geo/migrate/foo'                                                          | [:database]
      'ee/db/geo/post_migrate/foo'                                                     | [:database]
      'app/models/project_authorization.rb'                                            | [:database, :backend]
      'app/services/users/refresh_authorized_projects_service.rb'                      | [:database, :backend]
      'app/services/authorized_project_update/find_records_due_for_refresh_service.rb' | [:database, :backend]
      'lib/gitlab/background_migration.rb'                                             | [:database, :backend]
      'lib/gitlab/background_migration/foo'                                            | [:database, :backend]
      'ee/lib/gitlab/background_migration/foo'                                         | [:database, :backend]
      'ee/lib/ee/gitlab/background_migration/foo'                                      | [:database, :backend]
      'lib/gitlab/database.rb'                                                         | [:database, :backend]
      'lib/gitlab/database/foo'                                                        | [:database, :backend]
      'ee/lib/gitlab/database/foo'                                                     | [:database, :backend]
      'lib/gitlab/sql/foo'                                                             | [:database, :backend]
      'rubocop/cop/migration/foo'                                                      | [:database]

      'db/fixtures/foo.rb'                                 | [:backend]
      'ee/db/fixtures/foo.rb'                              | [:backend]

      'qa/foo' | [:qa]
      'ee/qa/foo' | [:qa]

      'workhorse/main.go' | [:workhorse]
      'workhorse/internal/upload/upload.go' | [:workhorse]

      'locale/gitlab.pot' | [:none]

      'FOO'          | [:none]
      'foo'          | [:none]

      'foo/bar.rb'  | [:backend]
      'foo/bar.js'  | [:frontend]
      'foo/bar.txt' | [:none]
      'foo/bar.md'  | [:none]

      'ee/config/metrics/counts_7d/20210216174919_g_analytics_issues_weekly.yml' | [:analytics_instrumentation]
      'lib/gitlab/usage_data_counters/aggregated_metrics/common.yml' | [:analytics_instrumentation]
      'lib/gitlab/usage_data_counters/hll_redis_counter.rb' | [:backend, :analytics_instrumentation]
      'lib/gitlab/tracking.rb' | [:backend, :analytics_instrumentation]
      'lib/gitlab/usage/service_ping_report.rb' | [:backend, :analytics_instrumentation]
      'lib/gitlab/usage/metrics/key_path_processor.rb' | [:backend, :analytics_instrumentation]
      'spec/lib/gitlab/tracking_spec.rb' | [:backend, :analytics_instrumentation]
      'app/helpers/tracking_helper.rb' | [:backend, :analytics_instrumentation]
      'spec/helpers/tracking_helper_spec.rb' | [:backend, :analytics_instrumentation]
      'lib/generators/rails/usage_metric_definition_generator.rb' | [:backend, :analytics_instrumentation]
      'spec/lib/generators/usage_metric_definition_generator_spec.rb' | [:backend, :analytics_instrumentation]
      'config/metrics/schema.json' | [:analytics_instrumentation]
      'app/assets/javascripts/tracking/foo.js' | [:frontend, :analytics_instrumentation]
      'spec/frontend/tracking/foo.js' | [:frontend, :analytics_instrumentation]
      'spec/frontend/tracking_spec.js' | [:frontend, :analytics_instrumentation]
      'lib/gitlab/usage_database/foo.rb' | [:backend]
      'config/metrics/counts_7d/test_metric.yml' | [:analytics_instrumentation]
      'config/events/snowplow_event.yml' | [:analytics_instrumentation]
      'config/metrics/schema.json' | [:analytics_instrumentation]
      'doc/api/usage_data.md' | [:analytics_instrumentation]
      'spec/lib/gitlab/usage_data_spec.rb' | [:analytics_instrumentation]
      'spec/lib/gitlab/usage/service_ping_report.rb' | [:backend, :analytics_instrumentation]
      'spec/lib/gitlab/usage/metrics/key_path_processor.rb' | [:backend, :analytics_instrumentation]
      'spec/support/matchers/internal_events_matchers.rb' | [:backend, :analytics_instrumentation]
      'spec/support_specs/matchers/internal_events_matchers_spec.rb' | [:backend, :analytics_instrumentation]
      'scripts/internal_events/cli/global_state.rb' | [:backend, :analytics_instrumentation]
      'spec/scripts/internal_events/cli_spec.rb' | [:backend, :analytics_instrumentation]

      'app/models/integration.rb' | [:import_integrate_be, :backend]
      'ee/app/models/integrations/github.rb' | [:import_integrate_be, :backend]
      'ee/app/models/ee/integrations/jira.rb' | [:import_integrate_be, :backend]
      'app/models/integrations/chat_message/pipeline_message.rb' | [:import_integrate_be, :backend]
      'app/models/jira_connect_subscription.rb' | [:import_integrate_be, :backend]
      'app/models/hooks/service_hook.rb' | [:import_integrate_be, :backend]
      'ee/app/models/ee/hooks/system_hook.rb' | [:import_integrate_be, :backend]
      'app/services/concerns/integrations/project_test_data.rb' | [:import_integrate_be, :backend]
      'ee/app/services/ee/integrations/test/project_service.rb' | [:import_integrate_be, :backend]
      'app/controllers/concerns/integrations/actions.rb' | [:import_integrate_be, :backend]
      'ee/app/controllers/concerns/ee/integrations/params.rb' | [:import_integrate_be, :backend]
      'ee/app/controllers/projects/integrations/jira/issues_controller.rb' | [:import_integrate_be, :backend]
      'app/controllers/projects/hooks_controller.rb' | [:import_integrate_be, :backend]
      'app/controllers/admin/hook_logs_controller.rb' | [:import_integrate_be, :backend]
      'app/controllers/groups/settings/integrations_controller.rb' | [:import_integrate_be, :backend]
      'app/controllers/jira_connect/branches_controller.rb' | [:import_integrate_be, :backend]
      'app/controllers/oauth/jira/authorizations_controller.rb' | [:import_integrate_be, :backend]
      'ee/app/finders/projects/integrations/jira/by_ids_finder.rb' | [:import_integrate_be, :database, :backend]
      'app/workers/jira_connect/sync_merge_request_worker.rb' | [:import_integrate_be, :backend]
      'app/workers/propagate_integration_inherit_worker.rb' | [:import_integrate_be, :backend]
      'app/workers/web_hooks/log_execution_worker.rb' | [:import_integrate_be, :backend]
      'app/workers/web_hook_worker.rb' | [:import_integrate_be, :backend]
      'app/workers/project_service_worker.rb' | [:import_integrate_be, :backend]
      'lib/atlassian/jira_connect/serializers/commit_entity.rb' | [:import_integrate_be, :backend]
      'lib/api/entities/project_integration.rb' | [:import_integrate_be, :backend]
      'lib/gitlab/hook_data/note_builder.rb' | [:import_integrate_be, :backend]
      'lib/gitlab/data_builder/note.rb' | [:import_integrate_be, :backend]
      'lib/gitlab/slash_commands/run.rb' | [:import_integrate_be, :backend]
      'lib/gitlab/web_hooks/recursion_detection.rb' | [:import_integrate_be, :backend]
      'ee/lib/ee/gitlab/integrations/sti_type.rb' | [:import_integrate_be, :backend]
      'ee/lib/ee/api/helpers/integrations_helpers.rb' | [:import_integrate_be, :backend]
      'ee/app/serializers/integrations/jira_serializers/issue_entity.rb' | [:import_integrate_be, :backend]
      'app/serializers/jira_connect/app_data_serializer.rb' | [:import_integrate_be, :backend]
      'lib/api/github/entities.rb' | [:import_integrate_be, :backend]
      'lib/api/v3/github.rb' | [:import_integrate_be, :backend]
      'app/services/clusters/integrations/prometheus_health_check_service.rb' | [:backend]
      'app/graphql/types/alert_management/integration_type.rb' | [:backend]

      'app/views/jira_connect/branches/new.html.haml' | [:import_integrate_fe, :frontend]
      'app/views/layouts/jira_connect.html.haml' | [:import_integrate_fe, :frontend]
      'app/assets/javascripts/jira_connect/branches/pages/index.vue' | [:import_integrate_fe, :frontend]
      'ee/app/views/projects/integrations/jira/issues/show.html.haml' | [:import_integrate_fe, :frontend]
      'ee/app/assets/javascripts/integrations/zentao/issues_list/graphql/queries/get_zentao_issues.query.graphql' | [:import_integrate_fe, :frontend]
      'app/assets/javascripts/pages/projects/settings/integrations/show/index.js' | [:import_integrate_fe, :frontend]
      'ee/app/assets/javascripts/pages/groups/hooks/index.js' | [:import_integrate_fe, :frontend]
      'app/views/clusters/clusters/_integrations_tab.html.haml' | [:frontend, :backend]
      'app/assets/javascripts/alerts_settings/graphql/fragments/integration_item.fragment.graphql' | [:frontend]
      'app/assets/javascripts/filtered_search/droplab/hook_input.js' | [:frontend]

      'app/views/layouts/header/_default.html.haml' | [:frontend, :backend]
      'app/views/layouts/header/_default.html.erb'  | [:frontend, :backend]
    end

    with_them do
      subject { project_helper.helper.categories_for_file(path) }

      it { is_expected.to eq(expected_categories) }
    end

    context 'when having specific changes' do
      where(:expected_categories, :patch, :changed_files) do
        [:analytics_instrumentation]                      | '+data-track-action'                           | ['components/welcome.vue']
        [:analytics_instrumentation]                      | '+ data: { track_label:'                       | ['admin/groups/_form.html.haml']
        [:analytics_instrumentation]                      | '+ Gitlab::Tracking.event'                     | ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml']
        [:analytics_instrumentation]                      | '+ Gitlab::Tracking.event("c", "a")'           | ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml']
        [:analytics_instrumentation]                      | '+ Gitlab::InternalEvents.track_event("c")'    | ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml']
        [:analytics_instrumentation]                      | '+ include Gitlab::InternalEventsTracking'     | ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml']
        [:analytics_instrumentation]                      | '+ track_internal_event("c")'                  | ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml']
        [:database, :backend, :analytics_instrumentation] | '+ count(User.active)'                         | ['usage_data.rb', 'lib/gitlab/usage_data.rb', 'ee/lib/ee/gitlab/usage_data.rb']
        [:database, :backend, :analytics_instrumentation] | '+ estimate_batch_distinct_count(User.active)' | ['usage_data.rb']
        [:backend, :analytics_instrumentation]            | '+ alt_usage_data(User.active)'                | ['lib/gitlab/usage_data.rb']
        [:backend, :analytics_instrumentation]            | '+ count(User.active)'                         | ['lib/gitlab/usage_data/topology.rb']
        [:backend, :analytics_instrumentation]            | '+ foo_count(User.active)'                     | ['lib/gitlab/usage_data.rb']
        [:backend]                                        | '+ count(User.active)'                         | ['user.rb']
        [:database, :backend]                             | '+ User.upsert({ name: "blah" })'              | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ User.upsert('                               | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ Organizations::OrganizationUser.upsert({'   | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ upsert({ name: "blah" })'                   | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ .upsert({ name: "blah" })'                  | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ .delete_all'                                | ['app/foo/bar.rb']
        [:database, :backend]                             | '+ .destroy_all'                               | ['app/foo/bar.rb']
        [:import_integrate_be, :database]                 | '+ add_column :integrations, :foo, :text'      | ['db/migrate/foo.rb']
        [:import_integrate_be, :database]                 | '+ create_table :zentao_tracker_data do |t|'   | ['ee/db/post_migrate/foo.rb']
        [:import_integrate_be, :backend]                  | '+ Integrations::Foo'                          | ['app/foo/bar.rb']
        [:import_integrate_be, :backend]                  | '+ project.execute_hooks(foo, :bar)'           | ['ee/lib/ee/foo.rb']
        [:import_integrate_be, :backend]                  | '+ project.execute_integrations(foo, :bar)'    | ['app/foo.rb']
        [:frontend, :analytics_instrumentation]           | '+ api.trackRedisCounterEvent("foo")'          | ['app/assets/javascripts/telemetry.js', 'ee/app/assets/javascripts/mr_widget.vue']
        [:frontend, :analytics_instrumentation]           | '+ api.trackRedisHllUserEvent("bar")'          | ['app/assets/javascripts/telemetry.js', 'ee/app/assets/javascripts/mr_widget.vue']
        [:frontend, :analytics_instrumentation]           | '+ InternalEvents.trackEvent("foo")'           | ['app/assets/javascripts/telemetry.js', 'ee/app/assets/javascripts/mr_widget.vue']
      end

      with_them do
        it 'has the correct categories' do
          changed_files.each do |file|
            allow(fake_git).to receive(:diff_for_file).with(file) { double(:diff, patch: patch) }

            expect(project_helper.helper.categories_for_file(file)).to eq(expected_categories)
          end
        end
      end
    end
  end

  describe '#file_lines' do
    let(:filename) { 'spec/foo_spec.rb' }
    let(:file_spy) { spy }

    it 'returns the chomped file lines' do
      expect(project_helper).to receive(:read_file).with(filename).and_return(file_spy)

      project_helper.file_lines(filename)

      expect(file_spy).to have_received(:lines).with(chomp: true)
    end
  end
end
