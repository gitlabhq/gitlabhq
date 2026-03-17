# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Exports::CreateService, :aggregate_failures, feature_category: :importers do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:organization) { create(:organization) }
    let_it_be(:groups) { create_list(:group, 2, owners: current_user) }
    let_it_be(:projects) { create_list(:project, 2, maintainers: current_user) }
    let(:source_hostname) { 'http://localhost' }
    let(:portable_params) { (groups + projects).map { |portable| { full_path: portable.full_path } } }
    let(:storage_config) do
      {
        provider: :aws,
        bucket: 'gitlab-exports',
        credentials: {
          aws_access_key_id: 'AwsUserAccessKey',
          aws_secret_access_key: 'aws/secret+access/key',
          region: 'us-east-1',
          path_style: false
        }
      }
    end

    subject(:result) do
      described_class.new(current_user, portable_params, storage_config, organization.id).execute
    end

    before do
      allow_next_instance_of(Fog::Storage) do |storage|
        allow(storage).to receive(:head_bucket).and_return(
          Excon::Response.new(status: 200)
        )
      end
    end

    shared_examples 'a success response' do
      it 'creates an offline export and returns a success response' do
        expect { result }.to change { Import::Offline::Export.count }.by(1)
          .and change { Import::Offline::Configuration.count }.by(1)

        expect(result).to be_success.and have_attributes(
          payload: be_a(Import::Offline::Export).and(
            have_attributes(user: current_user, source_hostname: source_hostname)
          )
        )
      end
    end

    shared_examples 'an error response' do |error:|
      it 'does not create an offline export and returns an error response' do
        expect { result }.to not_change { Import::Offline::Export.count }
          .and not_change { Import::Offline::Configuration.count }

        expect(result).to be_a(ServiceResponse)
          .and be_error
          .and have_attributes(message: include(error))
      end
    end

    it_behaves_like 'a success response'

    it 'creates self-relation exports for all groups and projects', :aggregate_failures do
      expect { result }.to change { BulkImports::Export.count }.by(4)

      offline_export = result.payload
      relation_exports = offline_export.bulk_import_exports

      expect(relation_exports).to all(have_attributes(
        user_id: current_user.id,
        relation: BulkImports::FileTransfer::BaseConfig::SELF_RELATION,
        status: BulkImports::Export::PENDING
      ))

      expect(relation_exports.pluck(:group_id)).to match_array([groups[0].id, groups[1].id, nil, nil])
      expect(relation_exports.pluck(:project_id)).to match_array([projects[0].id, projects[1].id, nil, nil])
    end

    it 'sets the organization_id on the offline export' do
      expect(result.payload).to have_attributes(organization_id: organization.id)
    end

    it 'enqueues the export worker' do
      expect(Import::Offline::ExportWorker).to receive(:perform_async).with(Integer)

      result
    end

    context 'when only groups are exported' do
      let(:portable_params) { [{ type: 'group', full_path: groups[0].full_path }] }

      it_behaves_like 'a success response'

      it 'creates self-relation exports only for groups' do
        expect { result }.to change { BulkImports::Export.count }.by(1)

        offline_export = result.payload

        expect(offline_export.bulk_import_exports).to all(have_attributes(
          group_id: groups[0].id,
          user_id: current_user.id,
          relation: BulkImports::FileTransfer::BaseConfig::SELF_RELATION,
          status: BulkImports::Export::PENDING
        ))
      end
    end

    context 'when only projects are exported' do
      let(:portable_params) { [{ type: 'project', full_path: projects[0].full_path }] }

      it_behaves_like 'a success response'

      it 'creates self-relation exports only for projects' do
        expect { result }.to change { BulkImports::Export.count }.by(1)

        offline_export = result.payload

        expect(offline_export.bulk_import_exports).to all(have_attributes(
          project_id: projects[0].id,
          user_id: current_user.id,
          relation: BulkImports::FileTransfer::BaseConfig::SELF_RELATION,
          status: BulkImports::Export::PENDING
        ))
      end
    end

    context 'when portables contain duplicate paths' do
      let(:portable_params) do
        [
          { full_path: groups[0].full_path },
          { full_path: groups[0].full_path },
          { full_path: groups[1].full_path },
          { full_path: projects[0].full_path },
          { full_path: projects[1].full_path },
          { full_path: projects[1].full_path }
        ]
      end

      it_behaves_like 'a success response'

      it 'does not create duplicate self relation exports' do
        expect { result }.to change { BulkImports::Export.count }.by(4)
      end
    end

    context 'when portables have descendants' do
      let_it_be(:subgroup) { create(:group, parent: groups[0]) }
      let_it_be(:child_project) { create(:project, group: groups[0]) }

      it 'does not create self relation exports for descendants' do
        result

        expect(BulkImports::Export.where(group_id: subgroup.id)).to be_empty
        expect(BulkImports::Export.where(project_id: child_project.id)).to be_empty
      end
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
          { full_path: groups[0].full_path },
          { full_path: unauthorized_group.full_path },
          { full_path: low_access_group.full_path },
          { full_path: 'nonexistent/group' },
          { full_path: projects[0].full_path },
          { full_path: unauthorized_project.full_path },
          { full_path: low_access_project.full_path },
          { full_path: 'nonexistent/project' }
        ]
      end

      it 'returns a service error without differentiating nonexistant and unauthorized portables' do
        invalid_paths = [
          unauthorized_group.full_path, low_access_group.full_path, 'nonexistent/group',
          unauthorized_project.full_path, low_access_project.full_path, 'nonexistent/project'
        ]

        expect(result).to be_a(ServiceResponse)
          .and be_error
          .and have_attributes(message: include(invalid_portable_error, *invalid_paths))
      end
    end

    context 'when portable params are not provided' do
      let(:portable_params) { [] }

      it_behaves_like 'an error response', error: 'Entity full paths must be provided'
    end

    context 'when a portable full path is not provided' do
      let(:portable_params) do
        [
          { type: 'group', full_path: '' },
          { type: 'project', full_path: projects[0].full_path }
        ]
      end

      it_behaves_like 'an error response', error: 'Entity full paths must be provided'
    end

    context 'when bucket cannot be reached' do
      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_raise(Excon::Error::BadRequest, 'Bad request')
        end
      end

      it_behaves_like 'an error response', error: 'Unable to access object storage bucket.'
    end

    context 'when an unexpected error is raised' do
      let(:raise_error_with_cause_proc) do
        proc do
          raise original_error
        rescue StandardError
          raise NoMethodError, 'undefined method caused by a connection error'
        end
      end

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_invoke(raise_error_with_cause_proc)
        end
      end

      context 'and the error was caused by an expected error when testing connection to the bucket' do
        let(:original_error) { Excon::Error::BadRequest.new('Bad request') }

        it_behaves_like 'an error response', error: 'Unable to access object storage bucket.'
      end

      context 'and the error is not caused by an expected error' do
        let(:original_error) { StandardError.new('unexpected') }

        it 'does not catch the error' do
          expect { result }.to raise_error(NoMethodError)
        end
      end
    end

    context 'when offline configuration fails validations' do
      before do
        storage_config[:bucket] = ''
      end

      it_behaves_like 'an error response', error: 'Bucket can\'t be blank'

      it 'does not attempt to connect with invalid configuration' do
        client_double = instance_double(Import::Clients::ObjectStorage)
        allow(Import::Clients::ObjectStorage).to receive(:new).and_return(client_double)

        expect(client_double).not_to receive(:test_connection!)

        result
      end
    end

    context 'when offline_transfer_exports is disabled' do
      before do
        stub_feature_flags(offline_transfer_exports: false)
      end

      it_behaves_like 'an error response', error: 'offline_transfer_exports feature flag must be enabled.'
    end
  end
end
