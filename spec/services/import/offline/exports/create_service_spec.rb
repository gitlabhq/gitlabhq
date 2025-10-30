# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Exports::CreateService, :aggregate_failures, feature_category: :importers do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:groups) { create_list(:group, 2, owners: current_user) }
    let_it_be(:projects) { create_list(:project, 2, maintainers: current_user) }

    let(:source_hostname) { 'https://offline-environment-gitlab.example.com' }
    let(:portable_params) do
      [
        { type: 'group', full_path: groups[0].full_path },
        { type: 'group', full_path: groups[1].full_path },
        { type: 'project', full_path: projects[0].full_path },
        { type: 'project', full_path: projects[1].full_path }
      ]
    end

    subject(:service) { described_class.new(current_user, source_hostname, portable_params) }

    shared_examples 'successfully creates an offline export' do
      it 'creates an offline export object' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload).to be_a(Import::Offline::Export)
        expect(result.payload.user).to eq(current_user)
        expect(result.payload.source_hostname).to eq(source_hostname)
      end
    end

    it_behaves_like 'successfully creates an offline export'

    context 'when only groups are exported' do
      let(:portable_params) { [{ type: 'group', full_path: groups[0].full_path }] }

      it_behaves_like 'successfully creates an offline export'
    end

    context 'when only projects are exported' do
      let(:portable_params) { [{ type: 'project', full_path: projects[0].full_path }] }

      it_behaves_like 'successfully creates an offline export'
    end

    context 'when portables contain duplicate paths' do
      let(:portable_params) do
        [
          { type: 'group', full_path: groups[0].full_path },
          { type: 'group', full_path: groups[0].full_path },
          { type: 'group', full_path: groups[1].full_path },
          { type: 'project', full_path: projects[0].full_path },
          { type: 'project', full_path: projects[1].full_path },
          { type: 'project', full_path: projects[1].full_path }
        ]
      end

      it_behaves_like 'successfully creates an offline export'
    end

    context 'when portables are invalid' do
      let_it_be(:unauthorized_group) { create(:group) }
      let_it_be(:unauthorized_project) { create(:project) }
      let_it_be(:low_access_group) { create(:group, maintainers: current_user) }
      let_it_be(:low_access_project) { create(:project, developers: current_user) }

      let(:invalid_portable_error) do
        'You do not have permission to export the following resources or they do not exist'
      end

      let(:portable_params) do
        [
          { type: 'group', full_path: groups[0].full_path },
          { type: 'group', full_path: unauthorized_group.full_path },
          { type: 'group', full_path: low_access_group.full_path },
          { type: 'group', full_path: 'nonexistent/group' },
          { type: 'project', full_path: projects[0].full_path },
          { type: 'project', full_path: unauthorized_project.full_path },
          { type: 'project', full_path: low_access_project.full_path },
          { type: 'project', full_path: 'nonexistent/project' }
        ]
      end

      it 'returns a service error without differentiating nonexistant and unauthorized portables' do
        invalid_paths = [
          unauthorized_group.full_path, low_access_group.full_path, 'nonexistent/group',
          unauthorized_project.full_path, low_access_project.full_path, 'nonexistent/project'
        ]

        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to include(invalid_portable_error)
        invalid_paths.each { |path| expect(result.message).to include(path) }
      end
    end

    context 'when a portable type is not provided' do
      let(:portable_params) do
        [
          { type: '', full_path: groups[0].full_path },
          { type: 'project', full_path: projects[0].full_path }
        ]
      end

      it 'returns a service error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to include('Entity types and full paths must be provided')
      end
    end

    context 'when a portable full path is not provided' do
      let(:portable_params) do
        [
          { type: 'group', full_path: '' },
          { type: 'project', full_path: projects[0].full_path }
        ]
      end

      it 'returns a service error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to include('Entity types and full paths must be provided')
      end
    end

    context 'when the offline export fails validations' do
      let(:source_hostname) { 'invalid-hostname' }

      it 'returns a service error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to include('must contain scheme and host')
      end
    end

    context 'when offline_transfer_exports is disabled' do
      before do
        stub_feature_flags(offline_transfer_exports: false)
      end

      it 'returns a service response error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('offline_transfer_exports feature flag must be enabled.')
      end
    end
  end
end
