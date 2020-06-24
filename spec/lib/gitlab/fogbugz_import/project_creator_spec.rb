# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FogbugzImport::ProjectCreator do
  let(:user) { create(:user) }

  let(:repo) do
    instance_double(Gitlab::FogbugzImport::Repository,
      name: 'Vim',
      safe_name: 'vim',
      path: 'vim',
      raw_data: '')
  end

  let(:uri) { 'https://testing.fogbugz.com' }
  let(:token) { 'token' }
  let(:fb_session) { { uri: uri, token: token } }
  let(:project_creator) { described_class.new(repo, fb_session, user.namespace, user) }

  subject do
    project_creator.execute
  end

  it 'creates project with private visibility level' do
    expect(subject.persisted?).to eq(true)
    expect(subject.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end
end
