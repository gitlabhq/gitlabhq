require "spec_helper"

describe StuckCiBuildsWorker do
  let!(:build) { create :ci_build }
  let(:worker) { described_class.new }

  subject do
    build.reload
    build.status
  end

  %w[pending running].each do |status|
    context "#{status} build" do
      before do
        build.update!(status: status)
      end

      it 'gets dropped if it was updated over 2 days ago' do
        build.update!(updated_at: 2.days.ago)
        worker.perform
        is_expected.to eq('failed')
      end

      it "is still #{status}" do
        build.update!(updated_at: 1.minute.ago)
        worker.perform
        is_expected.to eq(status)
      end
    end
  end

  %w[success failed canceled].each do |status|
    context "#{status} build" do
      before do
        build.update!(status: status)
      end

      it "is still #{status}" do
        build.update!(updated_at: 2.days.ago)
        worker.perform
        is_expected.to eq(status)
      end
    end
  end

  context "for deleted project" do
    before do
      build.update!(status: :running, updated_at: 2.days.ago)
      build.project.update(pending_delete: true)
    end

    it "does not drop build" do
      expect_any_instance_of(Ci::Build).not_to receive(:drop)
      worker.perform
    end
  end
end
