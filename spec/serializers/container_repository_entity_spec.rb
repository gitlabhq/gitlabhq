require 'spec_helper'

describe ContainerRepositoryEntity do
  let(:entity) do
    described_class.new(repository, request: request)
  end

  set(:project) { create(:project) }
  set(:user) { create(:user) }
  set(:repository) { create(:container_repository, project: project) }

  let(:request) { double('request') }

  subject { entity.as_json }

  before do
    stub_container_registry_config(enabled: true)
    allow(request).to receive(:project).and_return(project)
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes required informations'  do
    expect(subject).to include(:id, :path, :location, :tags_path)
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
