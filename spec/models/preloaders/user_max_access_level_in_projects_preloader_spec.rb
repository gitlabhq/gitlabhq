# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMaxAccessLevelInProjectsPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }

  let(:projects) { [project_1, project_2, project_3] }
  let(:query) { projects.each { |project| user.can?(:read_project, project) } }

  before do
    project_1.add_developer(user)
    project_2.add_developer(user)
  end

  context 'without preloader' do
    it 'runs N queries' do
      expect { query }.to make_queries(projects.size)
    end
  end

  describe '#execute', :request_store do
    let(:projects_arg) { projects }

    before do
      Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects_arg, user).execute
    end

    it 'avoids N+1 queries' do
      expect { query }.not_to make_queries
    end

    context 'when projects is an array of IDs' do
      let(:projects_arg) { [project_1.id, project_2.id, project_3.id] }

      it 'avoids N+1 queries' do
        expect { query }.not_to make_queries
      end
    end

    # Test for handling of SQL table name clashes.
    context 'when projects is a relation including project_authorizations' do
      let(:projects_arg) do
        Project.where(id: ProjectAuthorization.where(project_id: projects).select(:project_id))
      end

      it 'avoids N+1 queries' do
        expect { query }.not_to make_queries
      end
    end
  end
end
