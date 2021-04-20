# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSerializer do
  let_it_be(:project) { create(:project) }

  let(:provider_url) { 'http://provider.com' }

  context 'when serializer option is :import' do
    subject do
      described_class.new.represent(project, serializer: :import, provider_url: provider_url)
    end

    before do
      allow(ProjectImportEntity).to receive(:represent)
    end

    it 'represents with ProjectImportEntity' do
      subject

      expect(ProjectImportEntity)
        .to have_received(:represent)
              .with(project, serializer: :import, provider_url: provider_url, request: an_instance_of(EntityRequest))
    end
  end

  context 'when serializer option is omitted' do
    subject do
      described_class.new.represent(project)
    end

    before do
      allow(ProjectEntity).to receive(:represent)
    end

    it 'represents with ProjectEntity' do
      subject

      expect(ProjectEntity)
        .to have_received(:represent)
              .with(project, request: an_instance_of(EntityRequest))
    end
  end
end
