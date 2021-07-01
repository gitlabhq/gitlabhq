# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Confluence do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    before do
      subject.active = active
    end

    context 'when integration is active' do
      let(:active) { true }

      it { is_expected.not_to allow_value('https://example.com').for(:confluence_url) }
      it { is_expected.not_to allow_value('example.com').for(:confluence_url) }
      it { is_expected.not_to allow_value('foo').for(:confluence_url) }
      it { is_expected.not_to allow_value('ftp://example.atlassian.net/wiki').for(:confluence_url) }
      it { is_expected.not_to allow_value('https://example.atlassian.net').for(:confluence_url) }
      it { is_expected.not_to allow_value('https://.atlassian.net/wiki').for(:confluence_url) }
      it { is_expected.not_to allow_value('https://example.atlassian.net/wikifoo').for(:confluence_url) }
      it { is_expected.not_to allow_value('').for(:confluence_url) }
      it { is_expected.not_to allow_value(nil).for(:confluence_url) }
      it { is_expected.not_to allow_value('😊').for(:confluence_url) }
      it { is_expected.to allow_value('https://example.atlassian.net/wiki').for(:confluence_url) }
      it { is_expected.to allow_value('http://example.atlassian.net/wiki').for(:confluence_url) }
      it { is_expected.to allow_value('https://example.atlassian.net/wiki/').for(:confluence_url) }
      it { is_expected.to allow_value('http://example.atlassian.net/wiki/').for(:confluence_url) }
      it { is_expected.to allow_value('https://example.atlassian.net/wiki/foo').for(:confluence_url) }

      it { is_expected.to validate_presence_of(:confluence_url) }
    end

    context 'when integration is inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of(:confluence_url) }
      it { is_expected.to allow_value('foo').for(:confluence_url) }
    end
  end

  describe '#help' do
    it 'can correctly return a link to the project wiki when active' do
      project = create(:project)
      subject.project = project
      subject.active = true

      expect(subject.help).to include(Gitlab::Routing.url_helpers.project_wikis_url(project))
    end

    context 'when the project wiki is not enabled' do
      it 'returns nil when both active or inactive', :aggregate_failures do
        project = create(:project, :wiki_disabled)
        subject.project = project

        [true, false].each do |active|
          subject.active = active

          expect(subject.help).to be_nil
        end
      end
    end
  end

  describe 'Caching has_confluence on project_settings' do
    let(:project) { create(:project) }

    subject { project.project_setting.has_confluence? }

    it 'sets the property to true when integration is active' do
      create(:confluence_integration, project: project, active: true)

      is_expected.to be(true)
    end

    it 'sets the property to false when integration is not active' do
      create(:confluence_integration, project: project, active: false)

      is_expected.to be(false)
    end

    it 'creates a project_setting record if one was not already created' do
      expect { create(:confluence_integration) }.to change(ProjectSetting, :count).by(1)
    end
  end
end
