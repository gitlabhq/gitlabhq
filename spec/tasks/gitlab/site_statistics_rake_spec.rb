# frozen_string_literal: true
require 'rake_helper'

describe 'rake gitlab:refresh_site_statistics' do
  before do
    Rake.application.rake_require 'tasks/gitlab/site_statistics'

    create(:project)
    SiteStatistic.fetch.update(repositories_count: 0, wikis_count: 0)
  end

  let(:task) { 'gitlab:refresh_site_statistics' }

  it 'recalculates existing counters' do
    run_rake_task(task)

    expect(SiteStatistic.fetch.repositories_count).to eq(1)
    expect(SiteStatistic.fetch.wikis_count).to eq(1)
  end

  it 'displays message listing counters' do
    expect { run_rake_task(task) }.to output(/Updating Site Statistics counters:.* Repositories\.\.\. OK!.* Wikis\.\.\. OK!/m).to_stdout
  end
end
