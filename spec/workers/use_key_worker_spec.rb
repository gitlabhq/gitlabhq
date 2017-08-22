require 'spec_helper'

describe UseKeyWorker do
  describe "#perform" do
    it "updates the key's last_used_at attribute to the current time when it exists" do
      worker = described_class.new
      key = create(:key)
      current_time = Time.zone.now

      Timecop.freeze(current_time) do
        expect { worker.perform(key.id) }
          .to change { key.reload.last_used_at }.from(nil).to be_like_time(current_time)
      end
    end

    it "returns false and skips the job when the key doesn't exist" do
      worker = described_class.new
      key = create(:key)

      expect(worker.perform(key.id + 1)).to eq false
    end
  end
end
