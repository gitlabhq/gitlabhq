# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Branch do
  describe '#as_json' do
    subject { entity.as_json }

    let(:project) { create(:project, :public, :repository) }
    let(:repository) { project.repository }
    let(:branch) { repository.find_branch('master') }
    let(:entity) { described_class.new(branch, project: project) }

    it 'includes basic fields', :aggregate_failures do
      is_expected.to include(
        name: 'master',
        commit: a_kind_of(Hash),
        merged: false,
        protected: false,
        developers_can_push: false,
        developers_can_merge: false,
        can_push: false,
        default: true,
        web_url: Gitlab::Routing.url_helpers.project_tree_url(project, 'master')
      )
    end
  end
end
