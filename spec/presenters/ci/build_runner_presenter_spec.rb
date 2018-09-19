require 'spec_helper'

describe Ci::BuildRunnerPresenter do
  let(:presenter) { described_class.new(build) }
  let(:archive) { { paths: ['sample.txt'] } }
  let(:junit) { { junit: ['junit.xml'] } }

  let(:archive_expectation) do
    {
      artifact_type: :archive,
      artifact_format: :zip,
      paths: archive[:paths],
      untracked: archive[:untracked]
    }
  end

  let(:junit_expectation) do
    {
      name: 'junit.xml',
      artifact_type: :junit,
      artifact_format: :gzip,
      paths: ['junit.xml'],
      when: 'always'
    }
  end

  describe '#artifacts' do
    context "when option contains archive-type artifacts" do
      let(:build) { create(:ci_build, options: { artifacts: archive } ) }

      it 'presents correct hash' do
        expect(presenter.artifacts.first).to include(archive_expectation)
      end

      context "when untracked is specified" do
        let(:archive) { { untracked: true } }

        it 'presents correct hash' do
          expect(presenter.artifacts.first).to include(archive_expectation)
        end
      end

      context "when untracked and paths are missing" do
        let(:archive) { { when: 'always' } }

        it 'does not present hash' do
          expect(presenter.artifacts).to be_empty
        end
      end
    end

    context "when option has 'junit' keyword" do
      let(:build) { create(:ci_build, options: { artifacts: { reports: junit } } ) }

      it 'presents correct hash' do
        expect(presenter.artifacts.first).to include(junit_expectation)
      end
    end

    context "when option has both archive and reports specification" do
      let(:build) { create(:ci_build, options: { script: 'echo', artifacts: { **archive, reports: junit } } ) }

      it 'presents correct hash' do
        expect(presenter.artifacts.first).to include(archive_expectation)
        expect(presenter.artifacts.second).to include(junit_expectation)
      end

      context "when archive specifies 'expire_in' keyword" do
        let(:archive) { { paths: ['sample.txt'], expire_in: '3 mins 4 sec' } }

        it 'inherits expire_in from archive' do
          expect(presenter.artifacts.first).to include({ **archive_expectation, expire_in: '3 mins 4 sec' })
          expect(presenter.artifacts.second).to include({ **junit_expectation, expire_in: '3 mins 4 sec' })
        end
      end
    end

    context "when option has no artifact keywords" do
      let(:build) { create(:ci_build, :no_options) }

      it 'does not present hash' do
        expect(presenter.artifacts).to be_nil
      end
    end
  end
end
