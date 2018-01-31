require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180131101039_remove_duplicates_in_trending_projects.rb')

describe RemoveDuplicatesInTrendingProjects, :migration do
  describe '#up' do
    let(:projects) do
      [
        create(:project),
        create(:project),
        create(:project)
      ]
    end
    let!(:trending_projects) do
      create(:trending_project, project: projects[0])
      create(:trending_project, project: projects[0])
      create(:trending_project, project: projects[1])
      create(:trending_project, project: projects[2])
      create(:trending_project, project: projects[2])
    end

    it 'removes duplicated trending projects' do
      expect { migrate! }.to change { TrendingProject.count }.from(5).to(3)
    end
  end
end
