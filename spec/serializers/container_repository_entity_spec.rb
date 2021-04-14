# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepositoryEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:repository) { create(:container_repository, project: project) }

  let(:entity) { described_class.new(repository, request: request) }
  let(:request) { double('request') }

  subject { entity.as_json }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any,
      tags: %w[stable latest])
    allow(request).to receive(:project).and_return(project)
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes required informations' do
    expect(subject).to include(:id, :path, :location, :tags_path, :tags_count)
  end

  context 'when project is not preset in the request' do
    before do
      allow(request).to receive(:respond_to?).and_return(false)
      allow(request).to receive(:project).and_return(nil)
    end

    it 'uses project from the object' do
      expect(request.project).not_to equal(project)
      expect(subject).to include(:tags_path)
    end
  end

  context 'when user can manage repositories' do
    before do
      project.add_developer(user)
    end

    it 'exposes destroy_path' do
      expect(subject).to include(:destroy_path)
    end
  end

  context 'when user cannot manage repositories' do
    it 'does not expose destroy_path' do
      expect(subject).not_to include(:destroy_path)
    end
  end
end
