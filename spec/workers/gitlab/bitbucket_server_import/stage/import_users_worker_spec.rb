# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::ImportUsersWorker, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'returns without calling the next import stage' do # no-oped. Will be removed in follow up https://gitlab.com/gitlab-org/gitlab/-/issues/508916
      expect { worker.perform(project.id) }.not_to raise_error
    end
  end
end
