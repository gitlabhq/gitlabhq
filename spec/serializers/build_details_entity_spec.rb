require 'spec_helper'

describe BuildDetailsEntity do
  set(:user) { create(:admin) }

  it 'inherits from BuildEntity' do
    expect(described_class).to be < BuildEntity
  end

  describe '#as_json' do
    let(:project) { create(:project, :repository) }
    let!(:build) { create(:ci_build, :failed, project: project) }
    let(:request) { double('request') }
    let(:entity) { described_class.new(build, request: request, current_user: user, project: project) }
    subject { entity.as_json }

    before do
      allow(request).to receive(:current_user).and_return(user)
    end

    context 'when the user has access to issues and merge requests' do
      let!(:merge_request) do
        create(:merge_request, source_project: project, source_branch: build.ref)
      end

      before do
        allow(build).to receive(:merge_request).and_return(merge_request)
      end

      it 'contains the needed key value pairs' do
        expect(subject).to include(:coverage, :erased_at, :duration)
        expect(subject).to include(:artifacts, :runner, :pipeline)
        expect(subject).to include(:raw_path, :merge_request)
        expect(subject).to include(:new_issue_path)
      end

      it 'exposes details of the merge request' do
        expect(subject[:merge_request]).to include(:iid, :path)
      end

      context 'when the build has been erased' do
        let!(:build) { create(:ci_build, :erasable, project: project) }

        it 'exposes the user whom erased the build' do
          expect(subject).to include(:erase_path)
        end
      end

      context 'when the build has been erased' do
        let!(:build) { create(:ci_build, erased_at: Time.now, project: project, erased_by: user) }

        it 'exposes the user whom erased the build' do
          expect(subject).to include(:erased_by)
        end
      end
    end

    context 'when the user can only read the build' do
      let(:user) { create(:user) }

      it "won't display the paths to issues and merge requests" do
        expect(subject['new_issue_path']).to be_nil
        expect(subject['merge_request_path']).to be_nil
      end
    end
  end
end
