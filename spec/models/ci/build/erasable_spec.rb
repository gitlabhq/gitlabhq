require 'spec_helper'

describe Ci::Build::Erasable, models: true do
  shared_examples 'erasable' do
    it 'should remove artifact file' do
      expect(build.artifacts_file.exists?).to be_falsy
    end

    it 'should remove artifact metadata file' do
      expect(build.artifacts_metadata.exists?).to be_falsy
    end

    it 'should erase build trace in trace file' do
      expect(build.trace).to be_empty
    end

    it 'should set erased to true' do
      expect(build.erased?).to be true
    end

    it 'should set erase date' do
      expect(build.erased_at).to_not be_falsy
    end
  end

  context 'build is not erasable' do
    let!(:build) { create(:ci_build) }

    describe '#erase!' do
      it { expect { build.erase! }.to raise_error(StandardError, /Build not erasable!/ )}
    end

    describe '#erasable?' do
      subject { build.erasable? }
      it { is_expected.to eq false }
    end
  end

  context 'build is erasable' do
    let!(:build) { create(:ci_build_with_trace, :success, :artifacts) }

    describe '#erase!' do
      before { build.erase!(erased_by: user) }

      context 'erased by user' do
        let!(:user) { create(:user, username: 'eraser') }

        include_examples 'erasable'

        it 'should record user who erased a build' do
          expect(build.erased_by).to eq user
        end
      end

      context 'erased by system' do
        let(:user) { nil }

        include_examples 'erasable'

        it 'should not set user who erased a build' do
          expect(build.erased_by).to be_nil
        end
      end
    end

    describe '#erasable?' do
      subject { build.erasable? }
      it { is_expected.to eq true }
    end

    describe '#erased?' do
      let!(:build) { create(:ci_build_with_trace, :success, :artifacts) }
      subject { build.erased? }

      context 'build has not been erased' do
        it { is_expected.to be false }
      end

      context 'build has been erased' do
        before { build.erase! }

        it { is_expected.to be true }
      end
    end

    context 'metadata and build trace are not available' do
      let!(:build) { create(:ci_build, :success, :artifacts) }
      before { build.remove_artifacts_metadata! }

      describe '#erase!' do
        it 'should not raise error' do
          expect { build.erase! }.to_not raise_error
        end
      end
    end
  end
end
