# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:packages:build_composer_cache namespace rake task', :silence_stdout do
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:package_name2) { 'sample-project2' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:json2) { { 'name' => package_name2 } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }
  let_it_be(:project2) { create(:project, :custom_repo, files: { 'composer.json' => json2.to_json }, group: group) }

  let!(:package) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
  let!(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
  let!(:package3) { create(:composer_package, :with_metadatum, project: project2, name: package_name2, version: '3.0.0', json: json2) }

  before :all do
    Rake.application.rake_require 'tasks/gitlab/packages/composer'
  end

  subject do
    run_rake_task("gitlab:packages:build_composer_cache")
  end

  it 'generates the cache files' do
    expect { subject }.to change { Packages::Composer::CacheFile.count }.by(2)
  end
end
