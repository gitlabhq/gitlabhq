# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Routes::ValidateTask, feature_category: :permissions do
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

    subject(:run) { task.run }

    before do
      allow(API::API).to receive(:endpoints).and_return(
        [instance_double(Grape::Endpoint, routes: mock_routes)]
      )
    end

    context 'when routes have no authorization settings' do
      let(:route_settings) { {} }

      it 'completes successfully' do
        expect { run }.to output(/API route permissions are valid/).to_stdout
      end
    end

    context 'when routes have valid permissions' do
      let(:route_settings) { { authorization: { permissions: :read_project, boundary_type: :project } } }
      let(:mock_assignable) { instance_double(Authz::PermissionGroups::Assignable, boundaries: %w[project]) }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_project).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([mock_assignable])
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_permission).and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bundle exec rails generate authz:permission <NAME>
          #
          #    - GET /projects/:id/test: undefined_permission
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #
          #    - GET /projects/:id/test: undefined_permission
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_project).and_return([mock_assignable])
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_permission).and_return([])
      end

      it 'returns an error for the undefined permission' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bundle exec rails generate authz:permission <NAME>
          #
          #    - GET /projects/:id/test: undefined_permission
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #
          #    - GET /projects/:id/test: undefined_permission
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_one).and_return([])
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_two).and_return([])
      end

      it 'returns errors for all undefined permissions' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bundle exec rails generate authz:permission <NAME>
          #
          #    - GET /projects/:id/test: undefined_one
          #    - GET /projects/:id/test: undefined_two
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #
          #    - GET /projects/:id/test: undefined_one
          #    - GET /projects/:id/test: undefined_two
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_one).and_return([])
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:undefined_two).and_return([])
      end

      it 'returns errors for all undefined permissions' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions without definition files.
          #  Create definition files using: bundle exec rails generate authz:permission <NAME>
          #
          #    - GET /projects/:id/first: undefined_one
          #    - POST /projects/:id/second: undefined_two
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #
          #    - GET /projects/:id/first: undefined_one
          #    - POST /projects/:id/second: undefined_two
          #
          #######################################################################
        OUTPUT
      end
    end

    context 'when a route has a permission not in any assignable permission' do
      let(:route_settings) { { authorization: { permissions: :read_something, boundary_type: :project } } }

      before do
        allow(Authz::Permission).to receive(:defined?).with(:read_something).and_return(true)
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission).with(:read_something).and_return([])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes reference permissions not included in any assignable permission.
          #  Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
          #
          #    - GET /projects/:id/test: read_something
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
          #
          #    - GET /projects/:id/test: read_something
          #        Route boundaries: user
          #        Missing boundaries: user
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
          .with(:read_something).and_return([mock_assignable])
      end

      it 'returns an error for missing boundaries' do
        expect { run }.to raise_error(SystemExit).and output(<<~OUTPUT).to_stdout
          #######################################################################
          #
          #  The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
          #  Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
          #
          #    - GET /projects/:id/test: read_something
          #        Route boundaries: group, user
          #        Missing boundaries: user
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
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
        allow(Authz::PermissionGroups::Assignable).to receive(:for_permission)
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
          #
          #    - GET /projects/:id/test: read_something
          #
          #######################################################################
        OUTPUT
      end
    end
  end
end
