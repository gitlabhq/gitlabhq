require 'spec_helper'

describe ContainerTagEntity do
  let(:entity) do
    described_class.new(tag, request: request)
  end

  set(:project) { create(:project) }
  set(:user) { create(:user) }
  set(:repository) { create(:container_repository, name: 'image', project: project) }

  let(:request) { double('request') }
  let(:tag) { repository.tag('test') }

  subject { entity.as_json }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: /image/, tags: %w[test])
    allow(request).to receive(:project).and_return(project)
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes required informations'  do
    expect(subject).to include(:name, :location, :revision, :short_revision, :total_size, :created_at)
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
