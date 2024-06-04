# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketService, feature_category: :importers do
  let_it_be(:user) { create(:user, namespace: create(:user_namespace)) }
  let_it_be(:group) { create(:group) }

  let(:repo_path) { 'path/to/project' }
  let(:new_name) { nil }
  let(:target_namespace) { group.full_path }
  let(:repo) do
    Bitbucket::Representation::Repo.new(
      'id' => 1,
      'name' => 'foo',
      'description' => 'bar',
      'is_private' => false,
      'links' => {
        'clone' => [
          { 'name' => 'https', 'href' => 'https://bitbucket.org/repo/repo.git' }
        ]
      }
    )
  end

  let(:bitbucket_user) do
    Bitbucket::Representation::User.new(
      'username' => 'username',
      'name' => 'name'
    )
  end

  let(:params) do
    {
      bitbucket_username: 'username',
      bitbucket_app_password: 'password',
      repo_path: repo_path,
      target_namespace: target_namespace,
      new_name: new_name
    }
  end

  subject(:service) { described_class.new(user, params) }

  before_all do
    group.add_owner(user)
  end

  describe '#execute' do
    before do
      stub_application_setting(import_sources: %w[bitbucket])

      allow(service).to receive(:authorized?).and_return(true)

      allow_next_instance_of(Bitbucket::Client) do |client|
        allow(client).to receive(:repo).and_return(repo)
        allow(client).to receive(:user).and_return(bitbucket_user)
      end
    end

    describe 'user authorization' do
      context 'when user is authorized' do
        it 'executes the service & tracks access level' do
          result = service.execute

          expect(result).to include(status: :success)

          expect_snowplow_event(
            category: 'Import::BitbucketService',
            action: 'create',
            label: 'import_access_level',
            user: user,
            extra: { import_type: 'bitbucket', user_role: 'Owner' }
          )
        end

        context 'when new name is specified' do
          let(:new_name) { 'bar' }

          it 'creates a project with new name & path' do
            result = service.execute

            expect(result).to include(status: :success)

            project = group.projects.last

            expect(project.name).to eq(new_name)
            expect(project.path).to eq(new_name)
          end
        end

        context 'when repo path contains underscores' do
          let(:repo_path) { 'path___to___repo' }

          it 'normalizes repo path when fetching information from client' do
            expect_next_instance_of(Bitbucket::Client) do |client|
              expect(client).to receive(:repo).with('path/to/repo')
              expect(client).to receive(:user).and_return(bitbucket_user)
            end

            service.execute
          end
        end

        context 'when target namespace is invalid' do
          let(:target_namespace) { 'another_group/subgroup' }

          it 'creates project under user namespace' do
            create(:group, path: 'another_group')

            service.execute

            expect(user.projects.find_by_name('foo')).to be_present
          end
        end

        context 'when bitbucket user is not authorized' do
          it 'return an error' do
            allow_next_instance_of(Bitbucket::Client) do |client|
              allow(client).to receive(:user).and_return(nil)
            end

            result = service.execute

            expect(result).to include(
              message: 'Unable to authorize with Bitbucket. Check your credentials',
              status: :error,
              http_status: :unauthorized
            )
          end
        end
      end

      context 'when user is not authorized' do
        it 'returns an error' do
          allow(service).to receive(:authorized?).and_return(false)

          result = service.execute

          expect(result).to include(
            message: "You don't have permissions to import this project",
            status: :error,
            http_status: :unauthorized
          )
        end
      end
    end

    context 'when repo returns an error' do
      it 'returns an error' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:user).and_return(bitbucket_user)
          allow(client).to receive(:repo).and_return(
            Bitbucket::Representation::Repo.new('error' => { 'message' => 'error!' })
          )
        end

        result = service.execute

        expect(result).to include(
          message: 'Project path/to/project could not be found',
          status: :error,
          http_status: :unprocessable_entity
        )
      end
    end

    context 'when import source is disabled' do
      it 'returns an error' do
        stub_application_setting(import_sources: %w[])

        result = service.execute

        expect(result).to include(
          message: ['bitbucket import source is disabled'],
          status: :error,
          http_status: :forbidden
        )
      end
    end

    context 'when an exception is raised' do
      it 'logs and returns an error' do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:repo).and_raise(StandardError.new('Error!'))
          allow(client).to receive(:user).and_return(bitbucket_user)
        end

        expect(::Import::Framework::Logger)
          .to receive(:error)
          .with(
            message: 'BitBucket Cloud import failed',
            error: 'Import failed due to an error: Error!'
          )

        result = service.execute

        expect(result).to include(
          message: 'Import failed due to an error: Error!',
          status: :error,
          http_status: :bad_request
        )
      end
    end

    context 'when project could not be persisted' do
      it 'returns an error' do
        allow(repo).to receive(:description).and_return('*' * 2001)

        result = service.execute

        expect(result).to include(
          message: 'Description is too long (maximum is 2000 characters)',
          status: :error,
          http_status: :unprocessable_entity
        )
      end
    end
  end
end
