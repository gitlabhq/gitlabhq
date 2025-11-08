# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Header::Mapper, feature_category: :pipeline_composition do
  include StubRequests
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:local_file) { '/lib/gitlab/ci/templates/non-existent-file.yml' }
  let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
  let(:variables) { project.predefined_variables }
  let(:context_params) { { project: project, sha: project.commit.sha, user: user, variables: variables } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  let(:file_content) do
    <<~YAML
    inputs:
      environment:
        default: 'production'
    YAML
  end

  subject(:mapper) { described_class.new(values, context) }

  before do
    stub_full_request(remote_url).to_return(body: file_content)

    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#process' do
    subject(:process) { mapper.process }

    # Use shared examples
    it_behaves_like 'processes local file includes'
    it_behaves_like 'processes remote file includes'
    it_behaves_like 'processes project file includes'
    it_behaves_like 'handles empty includes'
    it_behaves_like 'handles invalid include types'
    it_behaves_like 'handles ambiguous specifications'
    it_behaves_like 'processes array of includes'

    # Header::Mapper specific tests
    context 'when using template includes' do
      let(:values) do
        { include: { 'template' => 'Auto-DevOps.gitlab-ci.yml' },
          inputs: { environment: { default: 'production' } } }
      end

      it 'raises an error for unsupported include type' do
        expect { process }.to raise_error(described_class::AmbigiousSpecificationError)
      end
    end

    context 'when using component includes' do
      let(:values) do
        { include: { 'component' => 'path/to/component@1.0' },
          inputs: { environment: { default: 'production' } } }
      end

      it 'raises an error for unsupported include type' do
        expect { process }.to raise_error(described_class::AmbigiousSpecificationError)
      end
    end

    context 'when files are returned' do
      let(:project_files) { { '/inputs.yml' => file_content } }
      let(:values) do
        { include: { 'local' => '/inputs.yml' },
          inputs: { environment: { default: 'production' } } }
      end

      around do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it 'returns files with inputs_only mode enabled' do
        files = process
        expect(files).to all(be_a(Gitlab::Ci::Config::External::File::Base))
        expect(files.first).to be_inputs_only
      end
    end
  end
end
