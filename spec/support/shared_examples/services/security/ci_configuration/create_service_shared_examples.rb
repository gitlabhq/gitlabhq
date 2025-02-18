# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'services security ci configuration create service' do |skip_w_params|
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let(:params) { {} }

    context 'user does not belong to project' do
      it 'returns an error status' do
        expect(result.status).to eq(:error)
        expect(result.payload[:success_path]).to be_nil
      end

      it 'does not track a snowplow event' do
        subject

        expect_no_snowplow_event
      end
    end

    context 'user belongs to project' do
      before do
        project.add_developer(user)
      end

      it 'does track the snowplow event' do
        subject

        expect_snowplow_event(**snowplow_event)
      end

      it 'raises exception if the user does not have permission to create a new branch' do
        allow(project).to receive(:repository).and_raise(Gitlab::Git::PreReceiveError, "You are not allowed to create protected branches on this project.")

        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError)
      end

      context 'when exception is raised' do
        let_it_be(:project) { create(:project, :repository) }
        let(:mock_sha) { '123456' }
        let(:commit_instance) { instance_double(Gitlab::Git::Commit, sha: mock_sha) }

        before do
          allow(project.repository).to receive(:add_branch).and_raise(StandardError, "The unexpected happened!")
        end

        context 'when branch was created' do
          before do
            allow(project.repository).to receive(:branch_exists?).and_return(true)
            allow(project.repository).to receive(:commit).with(branch_name).and_return(commit_instance)
          end

          it 'tries to rm branch' do
            expect(project.repository).to receive(:rm_branch).with(user, branch_name, target_sha: mock_sha)
            expect { subject }.to raise_error(StandardError)
          end
        end

        context 'when branch was not created' do
          before do
            allow(project.repository).to receive(:branch_exists?).and_return(false)
          end

          it 'does not try to rm branch' do
            expect(project.repository).not_to receive(:rm_branch)
            expect { subject }.to raise_error(StandardError)
          end
        end
      end

      context 'with no parameters' do
        it 'returns the path to create a new merge request' do
          expect(result.status).to eq(:success)
          expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
        end
      end

      context 'when the project has a non-default ci config file' do
        before do
          project.ci_config_path = 'non-default/.gitlab-ci.yml'
        end

        it 'does track the snowplow event' do
          subject

          expect_snowplow_event(**snowplow_event)
        end
      end

      context 'when existing ci config contains anchors/aliases' do
        let(:params) { {} }
        let(:unsupported_yaml) do
          <<-YAML
          image: python:latest

          cache: &global_cache
            key: 'common-cache'
            paths:
              - .cache/pip
              - venv/

          test:
            cache:
              <<: *global_cache
              key: 'custom-cache'
            script:
              - python setup.py test
              - pip install tox flake8  # you can also use tox
              - tox -e py36,flake8
          YAML
        end

        it 'returns a ServiceResponse error' do
          expect(project).to receive(:ci_config_for).and_return(unsupported_yaml)

          expect(result).to be_kind_of(ServiceResponse)
          expect(result.status).to eq(:error)
          expect(result.message).to eq(
            _(".gitlab-ci.yml with aliases/anchors is not supported. Please change the CI configuration manually.")
          )
        end
      end

      context 'when parsing existing ci config gives a Psych error' do
        let(:params) { {} }
        let(:invalid_yaml) do
          <<-YAML
          image: python:latest

          test:
            script:
              - python setup.py test
              - pip install tox flake8  # you can also use tox
              - tox -e py36,flake8
          YAML
        end

        it 'returns a ServiceResponse error' do
          expect(project).to receive(:ci_config_for).and_return(invalid_yaml)
          expect(YAML).to receive(:safe_load).and_raise(Psych::Exception)

          expect(result).to be_kind_of(ServiceResponse)
          expect(result.status).to eq(:error)
          expect(result.message).to match(/merge request creation failed/)
        end
      end

      context 'when parsing existing ci config gives any other error' do
        let(:params) { {} }
        let_it_be(:repository) { project.repository }

        it 'is successful' do
          expect(repository).to receive(:commit).twice.and_return(nil)
          expect(result.status).to eq(:success)
        end
      end

      unless skip_w_params
        context 'with parameters' do
          let(:params) { non_empty_params }

          it 'returns the path to create a new merge request' do
            expect(result.status).to eq(:success)
            expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
          end
        end
      end

      context 'when the project is empty' do
        let(:params) { nil }
        let_it_be(:project) { create(:project_empty_repo) }

        it 'returns a ServiceResponse error' do
          expect(result).to be_kind_of(ServiceResponse)
          expect(result.status).to eq(:error)
          expect(result.message).to eq('You must <a target="_blank" rel="noopener noreferrer" ' \
                                       'href="http://localhost/help/user/project/repository/_index.md' \
                                       '#add-files-to-a-repository">add at least one file to the repository' \
                                       '</a> before using Security features.')
        end
      end
    end
  end
end
