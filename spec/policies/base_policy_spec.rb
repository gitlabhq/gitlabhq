require 'spec_helper'

describe BasePolicy, models: true do
  let(:build) { Ci::Build.new }

  describe '.class_for' do
    it 'detects policy class based on the subject ancestors' do
      expect(described_class.class_for(build)).to eq(Ci::BuildPolicy)
    end

    it 'detects policy class for a presented subject' do
      presentee = Ci::BuildPresenter.new(build)

      expect(described_class.class_for(presentee)).to eq(Ci::BuildPolicy)
    end
  end
end
