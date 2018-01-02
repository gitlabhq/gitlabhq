require 'spec_helper'

describe UpdateAllMirrorsWorker do
  subject(:worker) { described_class.new }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#perform' do
    it 'does not execute if cannot get the lease' do
      create(:project, :mirror)

      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)

      expect(worker).not_to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    it 'schedules mirrors' do
      expect(worker).to receive(:schedule_mirrors!)

      worker.perform
    end
  end

  describe '#schedule_mirrors!' do
    def schedule_mirrors!(capacity:)
      allow(Gitlab::Mirror).to receive_messages(available_capacity: capacity)

      Sidekiq::Testing.fake! do
        worker.schedule_mirrors!
      end
    end

    def expect_import_status(project, status)
      expect(project.reload.import_status).to eq(status)
    end

    def expect_import_scheduled(*projects)
      projects.each { |project| expect_import_status(project, 'scheduled') }
    end

    def expect_import_not_scheduled(*projects)
      projects.each { |project| expect_import_status(project, 'none') }
    end

    context 'unlicensed' do
      it 'does not schedule when project does not have repository mirrors available' do
        project = create(:project, :mirror)

        stub_licensed_features(repository_mirrors: false)

        schedule_mirrors!(capacity: 5)

        expect_import_not_scheduled(project)
      end
    end

    context 'licensed' do
      def scheduled_mirror(at:, licensed:)
        namespace = create(:group, :public, plan: (:bronze_plan if licensed))
        project = create(:project, :public, :mirror, namespace: namespace)

        project.mirror_data.update!(next_execution_timestamp: at)
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        project
      end

      before do
        stub_licensed_features(repository_mirrors: true)
        stub_application_setting(check_namespace_plan: true)
        allow(Gitlab).to receive_messages(com?: true)
      end

      let!(:unlicensed_project) { scheduled_mirror(at: 4.weeks.ago, licensed: false) }
      let!(:earliest_project)   { scheduled_mirror(at: 3.weeks.ago, licensed: true) }
      let!(:latest_project)     { scheduled_mirror(at: 2.weeks.ago, licensed: true) }

      it "schedules all available mirrors when capacity is in excess" do
        schedule_mirrors!(capacity: 3)

        expect_import_scheduled(earliest_project, latest_project)
        expect_import_not_scheduled(unlicensed_project)
      end

      it "schedules all available mirrors when capacity is sufficient" do
        schedule_mirrors!(capacity: 2)

        expect_import_scheduled(earliest_project, latest_project)
        expect_import_not_scheduled(unlicensed_project)
      end

      it 'schedules mirrors by next_execution_timestamp when capacity is insufficient' do
        schedule_mirrors!(capacity: 1)

        expect_import_scheduled(earliest_project)
        expect_import_not_scheduled(unlicensed_project, latest_project)
      end
    end
  end
end
