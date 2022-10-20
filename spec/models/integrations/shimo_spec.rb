# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Integrations::Shimo do
  describe '#fields' do
    let(:shimo_integration) { build(:shimo_integration) }

    it 'returns custom fields' do
      expect(shimo_integration.fields.pluck(:name)).to eq(%w[external_wiki_url])
    end
  end

  describe '#create' do
    let_it_be(:project) { create(:project, :repository) }
    let(:external_wiki_url) { 'https://shimo.example.com/desktop' }
    let(:params) { { active: true, project: project, external_wiki_url: external_wiki_url } }

    context 'with valid params' do
      it 'creates the Shimo integration' do
        shimo = described_class.create!(params)

        expect(shimo.valid?).to be true
        expect(shimo.render?).to be true
        expect(shimo.external_wiki_url).to eq(external_wiki_url)
      end
    end

    context 'with invalid params' do
      it 'cannot create the Shimo integration without external_wiki_url' do
        params['external_wiki_url'] = nil
        expect { described_class.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'cannot create the Shimo integration with invalid external_wiki_url' do
        params['external_wiki_url'] = 'Fake Invalid URL'
        expect { described_class.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'Caching has_shimo on project_settings' do
    let_it_be(:project) { create(:project) }

    subject { project.project_setting.has_shimo? }

    it 'sets the property to true when integration is active' do
      create(:shimo_integration, project: project, active: true)

      is_expected.to be(true)
    end

    it 'sets the property to false when integration is not active' do
      create(:shimo_integration, project: project, active: false)

      is_expected.to be(false)
    end

    it 'creates a project_setting record if one was not already created' do
      expect { create(:shimo_integration) }.to change(ProjectSetting, :count).by(1)
    end
  end
end
