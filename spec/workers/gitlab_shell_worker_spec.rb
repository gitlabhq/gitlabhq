require 'spec_helper'

describe GitlabShellWorker do
  let(:worker) { described_class.new }

  describe '#perform with add_key' do
    it 'calls add_key on Gitlab::Shell' do
      expect_any_instance_of(Gitlab::Shell).to receive(:add_key).with('foo', 'bar')
      worker.perform(:add_key, 'foo', 'bar')
    end
  end

  describe '#perform with batch_add_keys_in_db_starting_from' do
    context 'when there are many keys in the DB' do
      before do
        @keys = []
        10.times do
          @keys << create(:key)
        end
      end

      it 'adds all the keys in the DB, starting from the given ID, to the authorized_keys file' do
        Gitlab::Shell.new.remove_all_keys

        worker.perform(:batch_add_keys_in_db_starting_from, @keys[3].id)

        file = File.read(Rails.root.join('tmp/tests/.ssh/authorized_keys'))
        expect(file.scan(/ssh-rsa/).count).to eq(7)

        expect(file).to_not include(Gitlab::Shell.strip_key(@keys[0].key))
        expect(file).to_not include(Gitlab::Shell.strip_key(@keys[2].key))
        expect(file).to include(Gitlab::Shell.strip_key(@keys[3].key))
        expect(file).to include(Gitlab::Shell.strip_key(@keys[9].key))
      end
    end
  end
end
