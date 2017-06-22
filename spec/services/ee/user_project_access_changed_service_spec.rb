require 'spec_helper'

describe EE::UserProjectAccessChangedService do
  let(:service) { UserProjectAccessChangedService.new([1, 2]) }

  describe '#execute' do
    it 'sticks all the updated users and returns the original result' do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
        .with([[1], [2]])
        .and_return(10)

      [1, 2].each do |id|
        expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
          .with(:user, id)
          .ordered
      end

      expect(service.execute).to eq(10)
    end
  end
end
