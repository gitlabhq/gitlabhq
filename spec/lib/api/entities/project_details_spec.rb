# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProjectDetails, feature_category: :api do
  include ProjectForksHelper

  let_it_be(:project_with_repository_restriction) { create(:project, :public, :repository_private) }
  let(:member_user) { project_with_repository_restriction.first_owner }
  let(:forked_project) { fork_project(project) }

  subject(:output) { described_class.new(project, current_user: current_user).as_json }

  describe '#forked_from_project' do
    let(:current_user) { member_user }
    let(:project) { project_with_repository_restriction }

    it 'is nil for upstream projects' do
      expect(output[:forked_from_project]).to be_nil
    end

    it 'is set for forked projects' do
      expect(described_class.new(forked_project).as_json[:forked_from_project]).to include(id: project.id)
    end
  end
end
