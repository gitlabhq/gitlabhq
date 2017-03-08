require 'rails_helper'

describe RepositoryUpdateMirrorDispatchWorker do
  describe '#perform' do
    it 'executes project#update_mirror if can obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(true)
      expect_any_instance_of(Project).to receive(:update_mirror)

      project = create(:empty_project, :mirror)
      described_class.new.perform(project.id)
    end

    it 'just returns if cannot obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(false)
      expect_any_instance_of(Project).not_to receive(:update_mirror)

      project = create(:empty_project, :mirror)
      described_class.new.perform(project.id)
    end
  end
end
