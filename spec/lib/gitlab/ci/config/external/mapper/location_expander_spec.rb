# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::LocationExpander, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:sha) { project.commit.sha }

  let(:context) do
    Gitlab::Ci::Config::External::Context.new(project: project, user: user, sha: sha)
  end

  subject(:location_expander) { described_class.new(context) }

  describe '#process' do
    subject(:process) { location_expander.process(locations) }

    context 'when there are project files' do
      let(:locations) do
        [{ project: 'gitlab-org/gitlab-1', file: ['builds.yml', 'tests.yml'] },
         { project: 'gitlab-org/gitlab-2', file: 'deploy.yml' }]
      end

      it 'returns expanded locations' do
        is_expected.to eq(
          [{ project: 'gitlab-org/gitlab-1', file: 'builds.yml' },
           { project: 'gitlab-org/gitlab-1', file: 'tests.yml' },
           { project: 'gitlab-org/gitlab-2', file: 'deploy.yml' }]
        )
      end
    end

    context 'when there are local files' do
      let(:locations) do
        [{ local: 'builds/*.yml' },
         { local: 'tests.yml' }]
      end

      let(:project_files) do
        { 'builds/1.yml' => 'a', 'builds/2.yml' => 'b', 'tests.yml' => 'c' }
      end

      around do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it 'returns expanded locations' do
        is_expected.to eq(
          [{ local: 'builds/1.yml' },
           { local: 'builds/2.yml' },
           { local: 'tests.yml' }]
        )
      end
    end

    context 'when there are other files' do
      let(:locations) do
        [{ remote: 'https://gitlab.com/gitlab-org/gitlab-ce/raw/master/.gitlab-ci.yml' }]
      end

      it 'returns the same location' do
        is_expected.to eq(locations)
      end
    end
  end
end
