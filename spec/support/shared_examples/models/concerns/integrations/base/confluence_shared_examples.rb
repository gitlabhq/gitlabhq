# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Confluence do
  let_it_be(:project) { create(:project) }

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
      subject.project = project
      subject.active = true

      expect(subject.help).to include(Gitlab::Routing.url_helpers.project_wikis_url(project))
    end

    context 'when the project wiki is not enabled' do
      before do
        allow(project).to receive(:wiki_enabled?).and_return(false)
      end

      it 'returns nil when both active or inactive', :aggregate_failures do
        [true, false].each do |active|
          subject.active = active

          expect(subject.help).to be_nil
        end
      end
    end
  end

  describe '#avatar_url' do
    it 'returns the avatar image path' do
      expect(subject.avatar_url).to eq(ActionController::Base.helpers.image_path('confluence.svg'))
    end
  end

  describe 'Caching has_confluence on project_settings' do
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
      expect { create(:confluence_integration) }.to change { ProjectSetting.count }.by(1)
    end
  end
end
