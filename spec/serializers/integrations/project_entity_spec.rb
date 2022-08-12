# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ProjectEntity do
  let_it_be(:project) { create(:project, :with_avatar) }

  let(:entity) do
    described_class.new(project)
  end

  context 'as json' do
    include Gitlab::Routing.url_helpers

    subject { entity.as_json }

    it 'contains needed attributes' do
      expect(subject).to include(
        id: project.id,
        avatar_url: include('uploads'),
        name: project.name,
        full_path: project_path(project),
        full_name: project.full_name
      )
    end
  end
end
