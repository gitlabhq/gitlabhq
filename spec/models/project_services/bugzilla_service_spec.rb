# frozen_string_literal: true

require 'spec_helper'

describe BugzillaService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }
      it_behaves_like 'issue tracker service URL attribute', :project_url
      it_behaves_like 'issue tracker service URL attribute', :issues_url
      it_behaves_like 'issue tracker service URL attribute', :new_issue_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end
  end

  context 'overriding properties' do
    let(:default_title) { 'JIRA' }
    let(:default_description) { 'JiraService|Jira issue tracker' }
    let(:url) { 'http://bugzilla.example.com' }
    let(:access_params) do
      { project_url: url, issues_url: url, new_issue_url: url }
    end

    # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab-ce/issues/63084
    context 'when data are stored in properties' do
      let(:properties) { access_params.merge(title: title, description: description) }
      let(:service) do
        create(:bugzilla_service, :without_properties_callback, properties: properties)
      end

      include_examples 'issue tracker fields'
    end

    context 'when data are stored in separated fields' do
      let(:service) do
        create(:bugzilla_service, title: title, description: description, properties: access_params)
      end

      include_examples 'issue tracker fields'
    end

    context 'when data are stored in both properties and separated fields' do
      let(:properties) { access_params.merge(title: 'wrong title', description: 'wrong description') }
      let(:service) do
        create(:bugzilla_service, :without_properties_callback, title: title, description: description, properties: properties)
      end

      include_examples 'issue tracker fields'
    end

    context 'when no title & description are set' do
      let(:service) do
        create(:bugzilla_service, properties: access_params)
      end

      it 'returns default values' do
        expect(service.title).to eq('Bugzilla')
        expect(service.description).to eq('Bugzilla issue tracker')
      end
    end
  end
end
