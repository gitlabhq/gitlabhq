# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepositoriesSerializer do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:resource) { create(:container_repository, name: 'image', project: project) }
  let(:params) { { current_user: user, project: project } }

  before do
    project.add_developer(user)

    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: /image/, tags: %w[rootA latest])
  end

  describe '#represent' do
    subject do
      described_class.new(params).represent(resource)
    end

    it 'has basic attributes' do
      expect(subject).to include(:id, :name, :path, :location, :created_at, :tags_path, :destroy_path)
    end
  end

  describe '#represent_read_only' do
    subject do
      described_class.new(current_user: user, project: project).represent_read_only(resource)
    end

    it 'does not include destroy_path' do
      expect(subject).to include(:id, :name, :path, :location, :created_at, :tags_path)
      expect(subject).not_to include(:destroy_path)
    end
  end

  describe '#with_pagination' do
    let(:request) do
      double(
        url: "#{Gitlab.config.gitlab.url}:8080/#{project.namespace_id}/#{project.id}/container_registry?#{query.to_query}",
        query_parameters: query
      )
    end

    let(:response) { spy('response') }
    let(:resource) { ContainerRepository.all }
    let(:query) { { page: 1, per_page: 2 } }

    let(:serializer) do
      described_class
        .new(current_user: user, project: project)
        .with_pagination(request, response)
    end

    subject do
      serializer.represent(resource)
    end

    it 'creates a paginated serializer' do
      expect(serializer).to be_paginated
    end

    context 'when multiple ContainerRepository objects are serialized' do
      before do
        create_list(:container_repository, 5, project: project)
      end

      it 'serializes appropriate number of objects' do
        expect(subject.count).to be 2
      end

      it 'appends relevant headers' do
        expect(response).to include_pagination_headers
        expect(response).to receive(:[]=).with('X-Total', '5')
        expect(response).to receive(:[]=).with('X-Total-Pages', '3')
        expect(response).to receive(:[]=).with('X-Per-Page', '2')

        subject
      end
    end
  end
end
