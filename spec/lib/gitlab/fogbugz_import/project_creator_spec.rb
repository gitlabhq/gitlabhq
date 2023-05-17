# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FogbugzImport::ProjectCreator, feature_category: :importers do
  let(:user) { create(:user) }
  let(:repo) do
    instance_double(Gitlab::FogbugzImport::Repository,
      name: 'Vim',
      safe_name: 'vim',
      path: 'vim',
      raw_data: '')
  end

  let(:repo_name) { 'new_name' }
  let(:uri) { 'https://testing.fogbugz.com' }
  let(:token) { 'token' }
  let(:fb_session) { { uri: uri, token: token } }
  let(:project_creator) { described_class.new(repo, repo_name, user.namespace, user, fb_session) }

  subject do
    project_creator.execute
  end

  before do
    stub_application_setting(import_sources: ['fogbugz'])
  end

  it 'creates project with private visibility level' do
    expect(subject.persisted?).to eq(true)
    expect(subject.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end

  it 'creates project with provided name and path' do
    expect(subject.name).to eq(repo_name)
    expect(subject.path).to eq(repo_name)
  end
end
