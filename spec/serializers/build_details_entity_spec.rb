require 'spec_helper'

describe BuildDetailsEntity do
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
      let(:user) { create(:admin) }
      let!(:merge_request) do
        create(:merge_request, source_project: project, source_branch: build.ref)
      end

      before do
        allow(build).to receive(:merge_request).and_return(merge_request)
      end

      it 'contains the needed key value pairs' do
        expect(subject).to include(:coverage, :erased_at, :duration)
        expect(subject).to include(:artifacts, :runner, :pipeline)
        expect(subject).to include(:raw_path, :merge_request_path, :new_issue_path)
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
