# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportEntity do
  include ImportHelper

  let_it_be(:project) { create(:project, import_status: :started, import_source: 'namespace/project') }

  let(:provider_url) { 'https://provider.com' }
  let(:entity) { described_class.represent(project, provider_url: provider_url) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'includes required fields' do
      expect(subject[:import_source]).to eq(project.import_source)
      expect(subject[:import_status]).to eq(project.import_status)
      expect(subject[:human_import_status_name]).to eq(project.human_import_status_name)
      expect(subject[:provider_link]).to eq(provider_project_link_url(provider_url, project[:import_source]))
    end
  end
end
