require "spec_helper"

describe StuckCiBuildsWorker do
  let!(:build) { create :ci_build }

  subject do
    build.reload
    build.status
  end

  %w(pending running).each do |status|
    context "#{status} build" do
      before do
        build.update!(status: status)
      end

      it 'gets dropped if it was updated over 2 days ago' do
        build.update!(updated_at: 2.days.ago)
        StuckCiBuildsWorker.new.perform
        is_expected.to eq('failed')
      end

      it "is still #{status}" do
        build.update!(updated_at: 1.minute.ago)
        StuckCiBuildsWorker.new.perform
        is_expected.to eq(status)
      end
    end
  end

  %w(success failed canceled).each do |status|
    context "#{status} build" do
      before do
        build.update!(status: status)
      end

      it "is still #{status}" do
        build.update!(updated_at: 2.days.ago)
        StuckCiBuildsWorker.new.perform
        is_expected.to eq(status)
      end
    end
  end
end
