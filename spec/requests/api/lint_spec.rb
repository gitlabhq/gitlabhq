# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Lint, feature_category: :pipeline_composition do
  describe 'GET /projects/:id/ci/lint' do
    subject(:ci_lint) do
      get api("/projects/#{project.id}/ci/lint", api_user),
        params: { content_ref: content_ref, dry_run: dry_run, include_jobs: include_jobs }
    end

    let(:project) { create(:project, :repository) }
    let(:content_ref) { nil }
    let(:dry_run) { nil }
    let(:include_jobs) { nil }

    RSpec.shared_examples 'valid config with warnings' do
      it 'passes validation with warnings' do
        ci_lint

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['valid']).to eq(true)
        expect(json_response['errors']).to eq([])
        expect(json_response['warnings']).not_to be_empty
      end
    end

    RSpec.shared_examples 'valid config without warnings' do
      it 'passes validation' do
        ci_lint

        included_config = YAML.safe_load(included_content, permitted_classes: [Symbol])
        root_config = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
        expected_yaml = included_config.merge(root_config).except(:include).deep_stringify_keys.to_yaml

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Hash
        expect(json_response['merged_yaml']).to eq(expected_yaml)
        expect(json_response['includes']).to contain_exactly(
          {
            'type' => 'local',
            'location' => 'another-gitlab-ci.yml',
            'blob' => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/another-gitlab-ci.yml",
            'raw' => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/another-gitlab-ci.yml",
            'extra' => {},
            'context_project' => project.full_path,
            'context_sha' => project.commit.sha
          }
        )
        expect(json_response['valid']).to eq(true)
        expect(json_response['warnings']).to eq([])
        expect(json_response['errors']).to eq([])
      end
    end

    RSpec.shared_examples 'invalid config' do
      it 'responds with errors about invalid configuration' do
        ci_lint

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['merged_yaml']).to eq(yaml_content)
        expect(json_response['includes']).to eq([])
        expect(json_response['valid']).to eq(false)
        expect(json_response['warnings']).to eq([])
        expect(json_response['errors']).to eq(['jobs config should contain at least one visible job'])
      end
    end

    context 'when unauthenticated' do
      let_it_be(:api_user) { nil }

      it 'returns authentication error' do
        ci_lint

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when authenticated as non-member' do
      let_it_be(:api_user) { create(:user) }

      let(:yaml_content) do
        { include: { local: 'another-gitlab-ci.yml' }, test: { stage: 'test', script: 'echo 1' } }.to_yaml
      end

      context 'when project is private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          stub_ci_pipeline_yaml_file(yaml_content)
        end

        it 'returns authentication error' do
          ci_lint

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when project is public' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          before do
            stub_ci_pipeline_yaml_file(yaml_content)
          end

          it 'returns pipeline creation error' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['merged_yaml']).to eq(nil)
            expect(json_response['includes']).to eq(nil)
            expect(json_response['valid']).to eq(false)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq(['Insufficient permissions to create a new pipeline'])
          end
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          let(:included_content) do
            { another_test: { stage: 'test', script: 'echo 1' } }.deep_stringify_keys.to_yaml
          end

          before do
            project.repository.create_file(
              project.creator,
              '.gitlab-ci.yml',
              yaml_content,
              message: 'Automatically created .gitlab-ci.yml',
              branch_name: 'master'
            )

            project.repository.create_file(
              project.creator,
              'another-gitlab-ci.yml',
              included_content,
              message: 'Automatically created another-gitlab-ci.yml',
              branch_name: 'master'
            )
          end

          it_behaves_like 'valid config without warnings'
        end
      end
    end

    context 'when authenticated as project guest' do
      let_it_be(:api_user) { create(:user) }

      before do
        project.add_guest(api_user)
      end

      it 'returns authentication error' do
        ci_lint

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as project developer' do
      let_it_be(:api_user) { create(:user) }

      before do
        project.add_developer(api_user)
      end

      context 'with no commit' do
        it 'returns error about providing content' do
          ci_lint

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['errors']).to match_array(['Please provide content of .gitlab-ci.yml'])
        end
      end

      context 'when repository is empty' do
        let(:project) { create(:project_empty_repo) }

        it 'returns 404 response' do
          ci_lint

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when repository does not exist' do
        let(:project) { create(:project) }

        it 'returns 404 response' do
          ci_lint

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with valid .gitlab-ci.yml content' do
        let(:yaml_content) do
          { include: { local: 'another-gitlab-ci.yml' }, test: { stage: 'test', script: 'echo 1' } }.to_yaml
        end

        let(:included_content) do
          { another_test: { stage: 'test', script: 'echo 1' } }.deep_stringify_keys.to_yaml
        end

        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            yaml_content,
            message: 'Automatically created .gitlab-ci.yml',
            branch_name: 'master'
          )

          project.repository.create_file(
            project.creator,
            'another-gitlab-ci.yml',
            included_content,
            message: 'Automatically created another-gitlab-ci.yml',
            branch_name: 'master'
          )
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          it_behaves_like 'valid config without warnings'
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          it_behaves_like 'valid config without warnings'
        end

        context 'when running with include jobs' do
          let(:include_jobs) { true }

          it_behaves_like 'valid config without warnings'

          it 'returns jobs key' do
            ci_lint

            expect(json_response).to have_key('jobs')
          end
        end

        context 'when running without include jobs' do
          let(:include_jobs) { false }

          it_behaves_like 'valid config without warnings'

          it 'does not return jobs key' do
            ci_lint

            expect(json_response).not_to have_key('jobs')
          end
        end

        context 'With warnings' do
          let(:yaml_content) { { job: { script: 'ls', rules: [{ when: 'always' }] } }.to_yaml }

          it_behaves_like 'valid config with warnings'
        end
      end

      context 'when including a component' do
        let_it_be(:component_project_files) do
          {
            'templates/component-x.yml' => <<~YAML
              job:
                script: echo 1
            YAML
          }
        end

        let_it_be(:component_project) { create(:project, :public, :custom_repo, files: component_project_files) }

        let_it_be(:project_files) do
          {
            '.gitlab-ci.yml' => <<~YAML
              include:
                - component: #{Gitlab.config.gitlab.host}/#{component_project.full_path}/component-x@master
            YAML
          }
        end

        let_it_be(:project) { create(:project, :custom_repo, files: project_files) }

        it 'passes validation' do
          ci_lint

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['merged_yaml']).to include("script: echo 1")
          expect(json_response['includes']).to contain_exactly(
            {
              'type' => 'component',
              'location' => "#{Gitlab.config.gitlab.host}/#{component_project.full_path}/component-x@master",
              'blob' => "http://#{Gitlab.config.gitlab.host}/#{component_project.full_path}/-/blob/#{component_project.repository.head_commit.sha}/templates/component-x.yml",
              'raw' => nil,
              'extra' => {},
              'context_project' => project.full_path,
              'context_sha' => project.repository.head_commit.sha
            }
          )
          expect(json_response['valid']).to eq(true)
          expect(json_response['warnings']).to eq([])
          expect(json_response['errors']).to eq([])
        end
      end

      context 'when including a project file' do
        let_it_be(:other_project_files) do
          {
            'tests.yml' => <<~YAML
              job:
                script: echo 1
            YAML
          }
        end

        let_it_be(:other_project) { create(:project, :public, :custom_repo, files: other_project_files) }

        let_it_be(:project_files) do
          {
            '.gitlab-ci.yml' => <<~YAML
              include:
                - project: #{other_project.full_path}
                  ref: master
                  file: tests.yml
            YAML
          }
        end

        let_it_be(:project) { create(:project, :custom_repo, files: project_files) }

        it 'passes validation' do
          ci_lint

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['merged_yaml']).to include("script: echo 1")
          expect(json_response['includes']).to contain_exactly(
            {
              'type' => 'file',
              'location' => "tests.yml",
              'blob' => "http://#{Gitlab.config.gitlab.host}/#{other_project.full_path}/-/blob/#{other_project.repository.head_commit.sha}/tests.yml",
              'raw' => "http://#{Gitlab.config.gitlab.host}/#{other_project.full_path}/-/raw/#{other_project.repository.head_commit.sha}/tests.yml",
              'extra' => {
                'project' => other_project.full_path,
                'ref' => 'master'
              },
              'context_project' => project.full_path,
              'context_sha' => project.repository.head_commit.sha
            }
          )
          expect(json_response['valid']).to eq(true)
          expect(json_response['warnings']).to eq([])
          expect(json_response['errors']).to eq([])
        end
      end

      context 'with invalid .gitlab-ci.yml content' do
        let(:yaml_content) do
          { image: 'image:1.0', services: ['postgres'] }.deep_stringify_keys.to_yaml
        end

        before do
          stub_ci_pipeline_yaml_file(yaml_content)
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          it_behaves_like 'invalid config'
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          it_behaves_like 'invalid config'
        end

        context 'when running with include jobs' do
          let(:include_jobs) { true }

          it_behaves_like 'invalid config'

          it 'returns jobs key' do
            ci_lint

            expect(json_response).to have_key('jobs')
          end
        end

        context 'when running without include jobs' do
          let(:include_jobs) { false }

          it_behaves_like 'invalid config'

          it 'does not return jobs key' do
            ci_lint

            expect(json_response).not_to have_key('jobs')
          end
        end
      end

      context 'with different sha values' do
        let(:original_content) do
          { test: { stage: 'test', script: 'echo 1' } }.deep_stringify_keys.to_yaml
        end

        let(:first_edit) do
          { image: 'image:1.0', services: ['postgres'] }.deep_stringify_keys.to_yaml
        end

        let(:second_edit) do
          { new_test: { stage: 'test', script: 'echo 0' } }.deep_stringify_keys.to_yaml
        end

        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            original_content,
            message: 'Automatically created .gitlab-ci.yml',
            branch_name: 'master'
          )

          project.repository.update_file(
            project.creator,
            '.gitlab-ci.yml',
            first_edit,
            message: 'Automatically edited .gitlab-ci.yml',
            branch_name: 'master'
          )

          project.repository.create_branch('invalid-content', 'master')

          project.repository.update_file(
            project.creator,
            '.gitlab-ci.yml',
            second_edit,
            message: 'Automatically edited .gitlab-ci.yml again',
            branch_name: 'master'
          )

          project.repository.create_branch('valid-content', 'master')
        end

        context 'when latest .gitlab-ci.yml is valid' do
          # check with explicit content_ref
          let(:content_ref) { project.repository.commit.sha }

          it 'passes validation' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(second_edit)
            expect(json_response['valid']).to eq(true)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq([])
          end
        end

        context 'when previous .gitlab-ci.yml is invalid' do
          let(:content_ref) { project.repository.commit.parent.sha }

          it 'fails validation' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(first_edit)
            expect(json_response['valid']).to eq(false)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq(['jobs config should contain at least one visible job'])
          end
        end

        context 'when first .gitlab-ci.yml is valid' do
          let(:content_ref) { project.repository.commit.parent.parent.sha }

          it 'passes validation' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(original_content)
            expect(json_response['valid']).to eq(true)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq([])
          end
        end

        context 'when content_ref is not found' do
          let(:content_ref) { 'unknown' }

          it 'returns 404 response' do
            ci_lint

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when sha (deprecated) is used with valid configuration' do
          let(:sha) { project.repository.commit.sha }

          it 'passes validation' do
            get api("/projects/#{project.id}/ci/lint", api_user), params: { sha: sha, dry_run: dry_run, include_jobs: include_jobs }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(second_edit)
            expect(json_response['valid']).to eq(true)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq([])
          end
        end

        context 'when sha (deprecated) and content_ref are used at the same time' do
          let(:sha) { project.repository.commit.sha }

          it 'returns bad request' do
            get api("/projects/#{project.id}/ci/lint", api_user), params: { sha: sha, content_ref: sha }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('sha, content_ref are mutually exclusive')
          end
        end

        context 'when ref (deprecated) and dry_run_ref are used at the same time' do
          let(:sha) { project.repository.commit.sha }

          it 'returns bad request' do
            get api("/projects/#{project.id}/ci/lint", api_user), params: { ref: sha, dry_run_ref: sha }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('ref, dry_run_ref are mutually exclusive')
          end
        end

        context 'when content_ref is a valid ref name with invalid config' do
          let(:content_ref) { 'invalid-content' }

          it 'fails validation' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(first_edit)
            expect(json_response['valid']).to eq(false)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq(["jobs config should contain at least one visible job"])
          end
        end

        context 'when content_ref is a valid ref name with valid config' do
          let(:content_ref) { 'valid-content' }

          it 'passes validation' do
            ci_lint

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Hash
            expect(json_response['merged_yaml']).to eq(second_edit)
            expect(json_response['valid']).to eq(true)
            expect(json_response['warnings']).to eq([])
            expect(json_response['errors']).to eq([])
          end
        end
      end
    end
  end

  describe 'POST /projects/:id/ci/lint' do
    subject(:ci_lint) { post api("/projects/#{project.id}/ci/lint", api_user), params: { dry_run: dry_run, content: yaml_content, include_jobs: include_jobs } }

    let(:project) { create(:project, :repository) }
    let(:dry_run) { nil }
    let(:include_jobs) { nil }

    let_it_be(:api_user) { create(:user) }

    let_it_be(:yaml_content) do
      { include: { local: 'another-gitlab-ci.yml' }, test: { stage: 'test', script: 'echo 1' } }.to_yaml
    end

    let_it_be(:included_content) do
      { another_test: { stage: 'test', script: 'echo 1' } }.to_yaml
    end

    RSpec.shared_examples 'valid project config' do
      it 'passes validation' do
        ci_lint

        included_config = YAML.safe_load(included_content, permitted_classes: [Symbol])
        root_config = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
        expected_yaml = included_config.merge(root_config).except(:include).deep_stringify_keys.to_yaml

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Hash
        expect(json_response['merged_yaml']).to eq(expected_yaml)
        expect(json_response['includes']).to contain_exactly(
          {
            'type' => 'local',
            'location' => 'another-gitlab-ci.yml',
            'blob' => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/another-gitlab-ci.yml",
            'raw' => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/another-gitlab-ci.yml",
            'extra' => {},
            'context_project' => project.full_path,
            'context_sha' => project.commit.sha
          }
        )
        expect(json_response['valid']).to eq(true)
        expect(json_response['errors']).to eq([])
      end
    end

    RSpec.shared_examples 'invalid project config' do
      it 'responds with errors about invalid configuration' do
        ci_lint

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['merged_yaml']).to eq(yaml_content)
        expect(json_response['includes']).to eq([])
        expect(json_response['valid']).to eq(false)
        expect(json_response['errors']).to eq(['jobs config should contain at least one visible job'])
      end
    end

    context 'with an empty repository' do
      let_it_be(:empty_project) { create(:project_empty_repo) }
      let_it_be(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      before do
        empty_project.add_developer(api_user)
      end

      it 'passes validation without errors' do
        post api("/projects/#{empty_project.id}/ci/lint", api_user), params: { content: yaml_content }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['valid']).to eq(true)
        expect(json_response['errors']).to eq([])
      end
    end

    context 'when unauthenticated' do
      let_it_be(:api_user) { nil }

      it 'returns authentication error' do
        ci_lint

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is public' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it 'returns authentication error' do
          ci_lint

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authenticated as non-member' do
      context 'when project is private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'returns authentication error' do
          ci_lint

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when project is public' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          it 'returns authentication error' do
            ci_lint

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          before do
            project.repository.create_file(
              project.creator,
              'another-gitlab-ci.yml',
              included_content,
              message: 'Automatically created another-gitlab-ci.yml',
              branch_name: 'master'
            )
          end

          it 'returns authentication error' do
            ci_lint

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    context 'when authenticated as project guest' do
      before do
        project.add_guest(api_user)
      end

      it 'returns authentication error' do
        ci_lint

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as project developer' do
      before do
        project.add_developer(api_user)
      end

      context 'with valid .gitlab-ci.yml content' do
        before do
          project.repository.create_file(
            project.creator,
            'another-gitlab-ci.yml',
            included_content,
            message: 'Automatically created another-gitlab-ci.yml',
            branch_name: 'master'
          )
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          it_behaves_like 'valid project config'
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          it_behaves_like 'valid project config'

          context 'when running on a protected branch' do
            let_it_be(:yaml_content) do
              {
                include: { remote: 'https://test.example.com/${SECRET_TOKEN}.yml' },
                test: { stage: 'test', script: 'echo 1' }
              }.to_yaml
            end

            before do
              sha = project.repository.commit.sha # this is always the sha used by this endpoint for linting
              ref = Gitlab::Ci::RefFinder.new(project).find_by_sha(sha)

              create(:protected_branch, name: ref, project: project)
              create(:ci_variable, key: 'SECRET_TOKEN', value: 'secret!!!!!', project: project, protected: true)
            end

            it 'does not expand protected variables' do
              ci_lint

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['merged_yaml']).to be_nil
              expect(json_response['includes']).to be_nil
              expect(json_response['valid']).to be_falsey
              expect(json_response['errors']).to eq([
                'Included file `https://test.example.com/.yml` does not have YAML extension!'
              ])
            end
          end
        end

        context 'when running with include jobs param' do
          let(:include_jobs) { true }

          it_behaves_like 'valid project config'

          it 'contains jobs key' do
            ci_lint

            expect(json_response).to have_key('jobs')
          end
        end

        context 'when running without include jobs param' do
          let(:include_jobs) { false }

          it_behaves_like 'valid project config'

          it 'does not contain jobs key' do
            ci_lint

            expect(json_response).not_to have_key('jobs')
          end
        end
      end

      context 'when authenticated as project maintainer' do
        before do
          project.add_maintainer(api_user)
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          context 'when running on a protected branch' do
            let_it_be(:yaml_content) do
              {
                include: { remote: 'https://test.example.com/${SECRET_TOKEN}.yml' },
                test: { stage: 'test', script: 'echo 1' }
              }.to_yaml
            end

            before do
              sha = project.repository.commit.sha # this is always the sha used by this endpoint for linting
              ref = Gitlab::Ci::RefFinder.new(project).find_by_sha(sha)

              create(:protected_branch, name: ref, project: project)
              create(:ci_variable, key: 'SECRET_TOKEN', value: 'secret!!!!!', project: project, protected: true)

              stub_request(:get, "https://test.example.com/secret!!!!!.yml")
            end

            it 'expands protected variables', :aggregate_failures do
              ci_lint

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['merged_yaml']).to be_nil
              expect(json_response['includes']).to be_nil
              expect(json_response['valid']).to be_falsey
              expect(json_response['errors']).to eq([
                'Included file `https://test.example.com/secret!!!!!.yml` is empty or does not exist!'
              ])
            end
          end
        end
      end

      context 'with invalid .gitlab-ci.yml content' do
        let(:yaml_content) do
          { image: 'image:1.0', services: ['postgres'] }.deep_stringify_keys.to_yaml
        end

        context 'when running as dry run' do
          let(:dry_run) { true }

          it_behaves_like 'invalid project config'
        end

        context 'when running static validation' do
          let(:dry_run) { false }

          it_behaves_like 'invalid project config'
        end

        context 'when running with include jobs set to false' do
          let(:include_jobs) { false }

          it_behaves_like 'invalid project config'

          it 'does not contain jobs key' do
            ci_lint

            expect(json_response).not_to have_key('jobs')
          end
        end

        context 'when running with param include jobs' do
          let(:include_jobs) { true }

          it_behaves_like 'invalid project config'

          it 'contains jobs key' do
            ci_lint

            expect(json_response).to have_key('jobs')
          end
        end
      end
    end
  end
end
