# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkNamespaceEntity do
  include Gitlab::Routing.url_helpers
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:namespace) { create(:group, :with_avatar, description: 'test', developers: user) }
  let_it_be(:forked_project) { build(:project) }

  let(:memberships) do
    user.members.index_by(&:source_id)
  end

  let(:forked_projects) { { namespace.id => forked_project } }

  let(:entity) { described_class.new(namespace, current_user: user, project: project, memberships: memberships, forked_projects: forked_projects) }

  subject(:json) { entity.as_json }

  it 'renders json' do
    is_expected.not_to be_nil
  end

  %w[id
     name
     description
     markdown_description
     visibility
     full_name
     created_at
     updated_at
     avatar_url].each do |attribute|
    it "includes #{attribute}" do
      expect(json[attribute.to_sym]).to be_present
    end
  end

  it 'exposes path for forking project to the namespace' do
    expect(json[:fork_path]).to eq project_forks_path(project, namespace_key: namespace.id)
  end

  it 'exposes forked_project_path when fork exists in namespace' do
    expect(json[:forked_project_path]).to eql project_path(forked_project)
  end

  it 'exposes relative path to the namespace' do
    expect(json[:relative_path]).to eql polymorphic_path(namespace)
  end

  it 'exposes human readable permission level' do
    expect(json[:permission]).to eql 'Developer'
  end
end
