# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Routes::ValidateTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }

  describe '#json_schema_file' do
    it 'returns nil' do
      expect(task.send(:json_schema_file)).to be_nil
    end
  end

  describe '#base_error' do
    let(:route) do
      instance_double(
        Grape::Router::Route,
        request_method: 'POST',
        origin: '/api/:version/projects/:id/members'
      )
    end

    it 'returns a hash with method and path' do
      expect(task.send(:base_error, route)).to eq(
        method: 'POST',
        path: '/projects/:id/members'
      )
    end
  end

  describe '#run', :unlimited_max_formatted_output_length do
    let(:route_settings) { {} }
    let(:mock_route) do
      instance_double(
        Grape::Router::Route,
        settings: route_settings,
        request_method: 'GET',
        origin: '/api/:version/projects/:id/test'
      )
    end

    let(:mock_routes) { [mock_route] }
    let(:source_proc) { instance_double(Proc, source_location: [Rails.root.join('lib/api/test.rb').to_s, 42]) }

    subject(:run) { task.run }

    before do
      allow(API::API).to receive(:endpoints).and_return(
        [instance_double(Grape::Endpoint, routes: mock_routes, source: source_proc)]
      )
      allow(described_class::TODO_FILE).to receive_messages(exist?: true, readlines: [])

      # Skip test coverage validation by default -- tested separately below
      allow(task).to receive(:register_test_coverage).with(any_args)
      mock_scanner = instance_double(Tasks::Gitlab::Permissions::Routes::SpecPermissionScanner,
        insufficient_test_coverage: [])
      allow(task).to receive(:spec_permission_scanner).and_return(mock_scanner)
    end

    context 'when routes have no authorization settings but are listed in the TODO file' do
      let(:route_settings) { {} }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines).and_return(["GET /projects/:id/test\n"])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when routes have valid permissions' do
      let(:route_settings) { { authorization: { permissions: :read_project, boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when routes have multiple valid permissions' do
      let(:route_settings) { { authorization: { permissions: [:read_project, :read_issue], boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::Permission).to receive(:defined?).with(:read_issue).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_issue).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when a route has an undefined permission' do
      let(:route_settings) { { authorization: { permissions: :undefined_permission, boundary_type: :project } } }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:undefined_permission).and_return(false)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_permission).and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bin/permission <NAME>
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - GET /projects/:id/test: undefined_permission (lib/api/test.rb:42)
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - GET /projects/:id/test: undefined_permission (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has multiple permissions and one is undefined' do
      let(:route_settings) do
        { authorization: { permissions: [:read_project, :undefined_permission], boundary_type: :project } }
      end

      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::Permission).to receive(:defined?).with(:undefined_permission).and_return(false)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_permission).and_return([])
      end

      it 'returns an error for the undefined permission' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bin/permission <NAME>
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - GET /projects/:id/test: undefined_permission (lib/api/test.rb:42)
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - GET /projects/:id/test: undefined_permission (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has multiple undefined permissions' do
      let(:route_settings) do
        { authorization: { permissions: [:undefined_one, :undefined_two], boundary_type: :project } }
      end

      before do
        allow(Authz::Permission).to receive(:defined?).with(:undefined_one).and_return(false)
        allow(Authz::Permission).to receive(:defined?).with(:undefined_two).and_return(false)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_one).and_return([])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_two).and_return([])
      end

      it 'returns errors for all undefined permissions' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bin/permission <NAME>
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - GET /projects/:id/test: undefined_one (lib/api/test.rb:42)
          #    - GET /projects/:id/test: undefined_two (lib/api/test.rb:42)
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - GET /projects/:id/test: undefined_one (lib/api/test.rb:42)
          #    - GET /projects/:id/test: undefined_two (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when multiple routes have undefined permissions' do
      let(:mock_route_1) do
        instance_double(
          Grape::Router::Route,
          settings: { authorization: { permissions: :undefined_one, boundary_type: :project } },
          request_method: 'GET',
          origin: '/api/:version/projects/:id/first'
        )
      end

      let(:mock_route_2) do
        instance_double(
          Grape::Router::Route,
          settings: { authorization: { permissions: :undefined_two, boundary_type: :project } },
          request_method: 'POST',
          origin: '/api/:version/projects/:id/second'
        )
      end

      let(:mock_routes) { [mock_route_1, mock_route_2] }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:undefined_one).and_return(false)
        allow(Authz::Permission).to receive(:defined?).with(:undefined_two).and_return(false)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_one).and_return([])
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:undefined_two).and_return([])
      end

      it 'returns errors for all undefined permissions' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bin/permission <NAME>
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/permission_definitions/#permission-definition-file
          #
          #    - GET /projects/:id/first: undefined_one (lib/api/test.rb:42)
          #    - POST /projects/:id/second: undefined_two (lib/api/test.rb:42)
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - GET /projects/:id/first: undefined_one (lib/api/test.rb:42)
          #    - POST /projects/:id/second: undefined_two (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has a permission only in a deprecated assignable permission' do
      let(:route_settings) { { authorization: { permissions: :read_something, boundary_type: :project } } }
      let(:deprecated_assignable) do
        instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project], deprecated?: true)
      end

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([])
      end

      it 'returns an error because the assignable is deprecated' do
        expect { run }.to raise_error(SystemExit).and output(
          /routes reference permissions not included in any assignable permission/
        ).to_stdout
      end
    end

    context 'when a route has a permission not in any assignable permission' do
      let(:route_settings) { { authorization: { permissions: :read_something, boundary_type: :project } } }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission).with(:read_something)
          .and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#create-the-assignable-permission-file
          #
          #    - GET /projects/:id/test: read_something (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has a boundary_type not matching assignable permission boundaries' do
      let(:route_settings) { { authorization: { permissions: :read_something, boundary_type: :user } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#determining-boundaries
          #
          #    - GET /projects/:id/test: read_something (lib/api/test.rb:42)
          #        Route boundaries: user
          #        Assignable boundaries: project, group
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has boundaries array with some not matching assignable permission' do
      let(:route_settings) do
        {
          authorization: {
            permissions: :read_something,
            boundaries: [
              { boundary_type: :group, boundary_param: :namespace },
              { boundary_type: :user }
            ]
          }
        }
      end

      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[group]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error for missing boundaries' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/assignable_permissions/#determining-boundaries
          #
          #    - GET /projects/:id/test: read_something (lib/api/test.rb:42)
          #        Route boundaries: group, user
          #        Assignable boundaries: group
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has boundaries array fully matching assignable permission' do
      let(:route_settings) do
        {
          authorization: {
            permissions: :read_something,
            boundaries: [
              { boundary_type: :group, boundary_param: :namespace },
              { boundary_type: :user }
            ]
          }
        }
      end

      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[group user]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when a route has a valid boundary_type matching assignable permission' do
      let(:route_settings) { { authorization: { permissions: :read_something, boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project group]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when a route has no boundary_type' do
      let(:route_settings) { { authorization: { permissions: :read_something } } }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes define permissions but are missing a boundary_type.
          #  Add boundary_type to the route_setting :authorization.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/rest_api_implementation_guide/#step-5-add-authorization-decorators-to-api-endpoints
          #
          #    - GET /projects/:id/test: read_something (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has no authorization and is not in the TODO file' do
      let(:route_settings) { {} }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines).and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes are missing route_setting :authorization metadata.
          #  Add authorization metadata to the endpoint.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/rest_api_implementation_guide
          #
          #    - GET /projects/:id/test (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when multiple routes have no authorization and only some are in the TODO file' do
      let(:mock_route_1) do
        instance_double(
          Grape::Router::Route,
          settings: {},
          request_method: 'GET',
          origin: '/api/:version/projects/:id/first'
        )
      end

      let(:mock_route_2) do
        instance_double(
          Grape::Router::Route,
          settings: {},
          request_method: 'POST',
          origin: '/api/:version/projects/:id/second'
        )
      end

      let(:mock_routes) { [mock_route_1, mock_route_2] }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines)
          .and_return(["GET /projects/:id/first\n"])
      end

      it 'returns an error only for the unlisted route' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes are missing route_setting :authorization metadata.
          #  Add authorization metadata to the endpoint.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/rest_api_implementation_guide
          #
          #    - POST /projects/:id/second (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has skip_granular_token_authorization with a valid reason' do
      let(:route_settings) do
        { authorization: { skip_granular_token_authorization: :job_token_auth } }
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when a route has skip_granular_token_authorization: true without a reason' do
      let(:route_settings) { { authorization: { skip_granular_token_authorization: true } } }

      it 'returns an error' do
        valid_reasons = described_class::VALID_SKIP_REASONS.map { |r| ":#{r}" }.join(', ')

        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes use a missing or invalid skip_granular_token_authorization reason.
          #  Use one of: #{valid_reasons}
          #
          #    - GET /projects/:id/test: true (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has skip_granular_token_authorization with an invalid reason' do
      let(:route_settings) do
        { authorization: { skip_granular_token_authorization: :not_a_valid_reason } }
      end

      it 'returns an error' do
        valid_reasons = described_class::VALID_SKIP_REASONS.map { |r| ":#{r}" }.join(', ')

        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes use a missing or invalid skip_granular_token_authorization reason.
          #  Use one of: #{valid_reasons}
          #
          #    - GET /projects/:id/test: not_a_valid_reason (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when the TODO file does not exist' do
      let(:route_settings) { {} }

      before do
        allow(described_class::TODO_FILE).to receive(:exist?).and_return(false)
      end

      it 'treats all untagged routes as violations' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes are missing route_setting :authorization metadata.
          #  Add authorization metadata to the endpoint.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/rest_api_implementation_guide
          #
          #    - GET /projects/:id/test (lib/api/test.rb:42)
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when the TODO file has comments and blank lines' do
      let(:route_settings) { {} }

      before do
        allow(described_class::TODO_FILE).to receive(:readlines).and_return([
          "# This is a comment\n",
          "\n",
          "GET /projects/:id/test\n",
          "  \n"
        ])
      end

      it 'ignores comments and blank lines and completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when a route permission has insufficient test coverage' do
      let(:route_settings) { { authorization: { permissions: :read_project, boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      let(:mock_scanner) do
        instance_double(
          Tasks::Gitlab::Permissions::Routes::SpecPermissionScanner,
          insufficient_test_coverage: [{
            permission: 'read_project',
            route_count: 1,
            test_count: 0,
            routes: [{
              method: 'GET', path: '/projects/:id/test',
              source: 'lib/api/test.rb:42', permission: :read_project,
              spec_file: 'spec/requests/api/test_spec.rb'
            }]
          }],
          derive_spec_path: 'spec/requests/api/test_spec.rb'
        )
      end

      before do
        allow(task).to receive(:register_test_coverage).and_call_original
        allow(task).to receive(:spec_permission_scanner).and_return(mock_scanner)
        allow(mock_scanner).to receive(:add_route)
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'returns an error with route details' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following permissions have fewer tests than routes using them.
          #  Each route should have its own `it_behaves_like 'authorizing granular token permissions'` test.
          #  Add test coverage.
          #  Learn more: https://docs.gitlab.com/development/permissions/granular_access/rest_api_implementation_guide/#step-6-add-request-specs-for-the-endpoint
          #
          #    - read_project: 1 routes, 0 tests
          #        GET /projects/:id/test (lib/api/test.rb:42)
          #          Suggested spec: spec/requests/api/test_spec.rb
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route permission has sufficient test coverage' do
      let(:route_settings) { { authorization: { permissions: :read_project, boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      let(:mock_scanner) do
        instance_double(
          Tasks::Gitlab::Permissions::Routes::SpecPermissionScanner,
          insufficient_test_coverage: [],
          derive_spec_path: 'spec/requests/api/test_spec.rb'
        )
      end

      before do
        allow(task).to receive(:register_test_coverage).and_call_original
        allow(task).to receive(:spec_permission_scanner).and_return(mock_scanner)
        allow(mock_scanner).to receive(:add_route)
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_project).and_return([mock_assignable])
      end

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end
  end
end
