require 'spec_helper'

describe ScheduledTriggerWorker do
  subject { described_class.new.perform }

  context '#perform' do # TODO:
    it 'does' do
      is_expected.to be_nil
    end
  end
end
