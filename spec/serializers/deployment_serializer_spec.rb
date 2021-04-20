# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentSerializer do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, email: project.commit.author_email) }

  let(:resource) { create(:deployment, project: project, sha: project.commit.id) }
  let(:serializer) { described_class.new(request) }

  shared_examples 'json schema' do
    let(:json_entity) { subject.as_json }

    it 'matches deployment entity schema' do
      expect(json_entity).to match_schema('deployment')
    end
  end

  describe '#represent' do
    subject { serializer.represent(resource) }

    let(:request) { { project: project, current_user: user } }

    it_behaves_like 'json schema'
  end

  describe '#represent_concise' do
    subject { serializer.represent_concise(resource) }

    let(:request) { { project: project } }

    it_behaves_like 'json schema'
  end
end
