# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UpdateProjectRunnersOwnerService, '#execute', feature_category: :runner do
  let_it_be(:owner_group) { create(:group) }
  let_it_be(:owner_project) { create(:project, group: owner_group) }
  let_it_be(:new_projects) { create_list(:project, 2) }

  let_it_be(:owned_runner1) do
    create(:ci_runner, :project, projects: [owner_project, new_projects.first], tag_list: %w[tag1])
  end

  let_it_be(:owned_runner2) { create(:ci_runner, :project, projects: [owner_project], tag_list: %w[tag1 tag2]) }
  let_it_be(:owned_runner3) do
    create(:ci_runner, :project, projects: [owner_project, *new_projects.reverse], tag_list: %w[tag2])
  end

  let_it_be(:owned_runner4) do
    create(:ci_runner, :project, projects: [owner_project, *new_projects], tag_list: %w[tag1 tag2])
  end

  let_it_be(:other_runner) { create(:ci_runner, :project, projects: new_projects, tag_list: %w[tag1 tag2]) }
  let_it_be(:orphaned_runner) { create(:ci_runner, :project, :without_projects, tag_list: %w[tag1 tag2]) }

  let_it_be(:owned_runner1_manager) { create(:ci_runner_machine, runner: owned_runner1) }
  let_it_be(:owned_runner2_manager) { create(:ci_runner_machine, runner: owned_runner2) }
  let_it_be(:owned_runner3_manager) { create(:ci_runner_machine, runner: owned_runner3) }
  let_it_be(:owned_runner4_manager) { create(:ci_runner_machine, runner: owned_runner4) }

  let(:service) { described_class.new(owner_project.id) }

  subject(:execute) { service.execute }

  before_all do
    owner_project.destroy!
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  it 'updates sharding_key_id on affected runners', :aggregate_failures do
    expect { execute }
      # owned_runner1's owner project was deleted
      .to change { owned_runner1.reload.sharding_key_id }.from(owner_project.id).to(new_projects.first.id)
      .and change { owned_runner1_manager.reload.sharding_key_id }.from(owner_project.id).to(new_projects.first.id)
      .and change { tagging_sharding_key_id_for_runner(owned_runner1) }.from(owner_project.id).to(new_projects.first.id)
      # owned_runner2's owner project was deleted and there were no other associated projects to fall back to
      .and change { Ci::Runner.find_by_id(owned_runner2) }.to(nil) # delete, since no other project to adopt it
      .and change { Ci::RunnerManager.find_by_id(owned_runner2_manager) }.to(nil)
      .and change { Ci::RunnerTagging.find_by_runner_id(owned_runner2) }.to(nil)
      # owned_runner3's owner project was deleted
      .and change { owned_runner3.reload.sharding_key_id }.from(owner_project.id).to(new_projects.last.id)
      .and change { owned_runner3_manager.reload.sharding_key_id }.from(owner_project.id).to(new_projects.last.id)
      .and change { tagging_sharding_key_id_for_runner(owned_runner3) }.from(owner_project.id).to(new_projects.last.id)
      # owned_runner4's owner project was deleted
      .and change { owned_runner4.reload.sharding_key_id }.from(owner_project.id).to(new_projects.first.id)
      .and change { owned_runner4_manager.reload.sharding_key_id }.from(owner_project.id).to(new_projects.first.id)
      .and change { tagging_sharding_key_id_for_runner(owned_runner4) }.from(owner_project.id).to(new_projects.first.id)
      # runners whose owner project was not affected
      .and not_change { other_runner.reload.sharding_key_id }.from(new_projects.first.id)
      .and not_change { orphaned_runner.reload.sharding_key_id }
      .and not_change { tagging_sharding_key_id_for_runner(orphaned_runner) }

    expect(execute).to be_success
  end

  private

  def tagging_sharding_key_id_for_runner(runner)
    runner.taggings.pluck(:sharding_key_id).uniq.sole
  end
end
