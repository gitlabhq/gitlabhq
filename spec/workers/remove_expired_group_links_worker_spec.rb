require 'spec_helper'

describe RemoveExpiredGroupLinksWorker do
  describe '#perform' do
    let!(:expired_project_group_link) { create(:project_group_link, expires_at: 1.hour.ago) }
    let!(:project_group_link_expiring_in_future) { create(:project_group_link, expires_at: 10.days.from_now) }
    let!(:non_expiring_project_group_link) { create(:project_group_link, expires_at: nil) }

    it 'removes expired group links' do
      expect { subject.perform }.to change { ProjectGroupLink.count }.by(-1)
      expect(ProjectGroupLink.find_by(id: expired_project_group_link.id)).to be_nil
    end

    it 'leaves group links that expire in the future' do
      subject.perform
      expect(project_group_link_expiring_in_future.reload).to be_present
    end

    it 'leaves group links that do not expire at all' do
      subject.perform
      expect(non_expiring_project_group_link.reload).to be_present
    end
  end
end
