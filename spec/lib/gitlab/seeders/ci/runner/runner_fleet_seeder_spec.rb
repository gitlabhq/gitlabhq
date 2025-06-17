# frozen_string_literal: true

require 'spec_helper'

NULL_LOGGER = Gitlab::JsonLogger.new('/dev/null')

RSpec.describe ::Gitlab::Seeders::Ci::Runner::RunnerFleetSeeder, feature_category: :fleet_visibility do
  let_it_be(:user_organization) { create(:organization) }
  let_it_be(:user) { create(:user, :admin, username: 'test-admin', organizations: [user_organization]) }

  subject(:seeder) do
    described_class.new(NULL_LOGGER,
      username: user.username,
      registration_prefix: registration_prefix,
      runner_count: runner_count)
  end

  describe '#seed', :enable_admin_mode do
    subject(:seed) { seeder.seed }

    let(:runner_count) { 20 }
    let(:registration_prefix) { 'prefix-' }
    let(:runner_releases_url) do
      ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url
    end

    before do
      WebMock.stub_request(:get, runner_releases_url).to_return(
        body: '[]',
        status: 200,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'creates expected hierarchy', :aggregate_failures do
      expect { seed }.to change { Ci::Runner.count }.by(runner_count)
        .and change { Ci::Runner.instance_type.count }.by(1)
        .and change { Project.count }.by(3)
        .and change { Group.count }.by(6)

      expect(Group.search(registration_prefix)).to contain_exactly(
        an_object_having_attributes(name: "#{registration_prefix}top-level group 1"),
        an_object_having_attributes(name: "#{registration_prefix}top-level group 2"),
        an_object_having_attributes(name: "#{registration_prefix}group 1.1"),
        an_object_having_attributes(name: "#{registration_prefix}group 1.1.1"),
        an_object_having_attributes(name: "#{registration_prefix}group 1.1.2"),
        an_object_having_attributes(name: "#{registration_prefix}group 2.1")
      )

      expect(Project.search(registration_prefix)).to contain_exactly(
        an_object_having_attributes(name: "#{registration_prefix}project 1.1.1.1"),
        an_object_having_attributes(name: "#{registration_prefix}project 1.1.2.1"),
        an_object_having_attributes(name: "#{registration_prefix}project 2.1.1")
      )

      project_1_1_1_1 = Project.find_by_name("#{registration_prefix}project 1.1.1.1")
      project_1_1_2_1 = Project.find_by_name("#{registration_prefix}project 1.1.2.1")
      project_2_1_1 = Project.find_by_name("#{registration_prefix}project 2.1.1")
      expect(seed).to contain_exactly(
        { project_id: project_1_1_1_1.id, runner_ids: an_instance_of(Array) },
        { project_id: project_1_1_2_1.id, runner_ids: an_instance_of(Array) },
        { project_id: project_2_1_1.id, runner_ids: an_instance_of(Array) }
      )
      seed.each do |project|
        expect(project[:runner_ids].length).to be_between(0, 5)
        expect(Project.find(project[:project_id]).all_available_runners.ids).to include(*project[:runner_ids])
        expect(::Ci::Pipeline.for_project(project[:runner_ids])).to be_empty
        expect(::Ci::Build.where(runner_id: project[:runner_ids])).to be_empty
      end
    end

    context 'when number of group runners exceeds plan limit' do
      before do
        create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
      end

      it { is_expected.to be_nil }

      it 'does not change runner count' do
        expect { seed }.not_to change { Ci::Runner.count }
      end
    end

    context 'when number of project runners exceeds plan limit' do
      before do
        create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
      end

      it { is_expected.to be_nil }

      it 'does not change runner count' do
        expect { seed }.not_to change { Ci::Runner.count }
      end
    end

    context 'when organization is passed to the initializer' do
      let(:other_organization) { create(:organization) }

      subject(:seed_with_organization) do
        described_class.new(NULL_LOGGER,
          username: user.username,
          registration_prefix: registration_prefix,
          runner_count: runner_count,
          organization_id: other_organization.id
        ).seed
      end

      it 'assigns organization_id to created entities' do
        expect { seed_with_organization }.not_to raise_error
        expect(Group.search(registration_prefix).pluck(:organization_id)).to all(eq(other_organization.id))
      end
    end

    context 'when organization is not passed to the initializer' do
      it 'assigns organization_id of the user to created entities' do
        expect { seed }.not_to raise_error
        expect(Group.search(registration_prefix).pluck(:organization_id)).to all(eq(user.organizations.first.id))
      end
    end

    context 'when no organization can be used' do
      let(:user_without_org) { create(:user, organizations: []) }

      subject(:seed_without_organization) do
        described_class.new(NULL_LOGGER,
          username: user_without_org.username,
          registration_prefix: registration_prefix,
          runner_count: runner_count
        ).seed
      end

      it 'fails with error' do
        expect { seed_without_organization }.to raise_error(
          "No organization found. Ensure user has an organization or pass an organization_id"
        )
      end
    end
  end
end
