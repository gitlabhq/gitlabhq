# frozen_string_literal: true

require 'spec_helper'

describe GitlabIssueTrackerService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      subject { described_class.new(project: create(:project), active: true) }

      it { is_expected.to validate_presence_of(:issues_url) }
      it_behaves_like 'issue tracker service URL attribute', :issues_url
    end

    context 'when service is inactive' do
      subject { described_class.new(project: create(:project), active: false) }

      it { is_expected.not_to validate_presence_of(:issues_url) }
    end
  end

  describe 'project and issue urls' do
    let(:project) { create(:project) }
    let(:service) { project.create_gitlab_issue_tracker_service(active: true) }

    context 'with absolute urls' do
      before do
        allow(described_class).to receive(:default_url_options).and_return(script_name: "/gitlab/root")
      end

      it 'gives the correct path' do
        expect(service.project_url).to eq("http://#{Gitlab.config.gitlab.host}/gitlab/root/#{project.full_path}/issues")
        expect(service.new_issue_url).to eq("http://#{Gitlab.config.gitlab.host}/gitlab/root/#{project.full_path}/issues/new")
        expect(service.issue_url(432)).to eq("http://#{Gitlab.config.gitlab.host}/gitlab/root/#{project.full_path}/issues/432")
      end
    end

    context 'with relative urls' do
      before do
        allow(described_class).to receive(:default_url_options).and_return(script_name: "/gitlab/root")
      end

      it 'gives the correct path' do
        expect(service.issue_tracker_path).to eq("/gitlab/root/#{project.full_path}/issues")
        expect(service.new_issue_path).to eq("/gitlab/root/#{project.full_path}/issues/new")
        expect(service.issue_path(432)).to eq("/gitlab/root/#{project.full_path}/issues/432")
      end
    end
  end

  context 'overriding properties' do
    let(:url) { 'http://gitlab.example.com' }
    let(:access_params) do
      { project_url: url, issues_url: url, new_issue_url: url }
    end

    # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab-ce/issues/63084
    context 'when data are stored in properties' do
      let(:properties) { access_params.merge(title: title, description: description) }
      let(:service) { create(:gitlab_issue_tracker_service, properties: properties) }

      include_examples 'issue tracker fields'
    end

    context 'when data are stored in separated fields' do
      let(:service) do
        create(:gitlab_issue_tracker_service, title: title, description: description, properties: access_params)
      end

      include_examples 'issue tracker fields'
    end

    context 'when data are stored in both properties and separated fields' do
      let(:properties) { access_params.merge(title: 'wrong title', description: 'wrong description') }
      let(:service) do
        create(:gitlab_issue_tracker_service, title: title, description: description, properties: properties)
      end

      include_examples 'issue tracker fields'
    end

    context 'when no title & description are set' do
      let(:service) do
        create(:gitlab_issue_tracker_service, properties: access_params)
      end

      it 'returns default values' do
        expect(service.title).to eq('GitLab')
        expect(service.description).to eq('GitLab issue tracker')
      end
    end
  end
end
