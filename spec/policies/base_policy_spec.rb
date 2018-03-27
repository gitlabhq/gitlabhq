require 'spec_helper'

describe BasePolicy do
  describe '.class_for' do
    it 'detects policy class based on the subject ancestors' do
      expect(DeclarativePolicy.class_for(GenericCommitStatus.new)).to eq(CommitStatusPolicy)
    end

    it 'detects policy class for a presented subject' do
      presentee = Ci::BuildPresenter.new(Ci::Build.new)

      expect(DeclarativePolicy.class_for(presentee)).to eq(Ci::BuildPolicy)
    end

    it 'uses GlobalPolicy when :global is given' do
      expect(DeclarativePolicy.class_for(:global)).to eq(GlobalPolicy)
    end
  end
end
