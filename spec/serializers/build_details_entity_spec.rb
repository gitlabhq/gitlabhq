require 'spec_helper'

describe BuildDetailsEntity do
  it 'inherits from BuildEntity' do
    expect(described_class).to be < BuildEntity
  end

  describe '#as_json' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let!(:build) { create(:ci_build, :failed, project: project) }
    let(:request) { double('request') }
    let(:entity) { described_class.new(build, request: request, current_user: user, project: project) }
    subject { entity.as_json }

    before do
      allow(request).to receive(:current_user).and_return(user)

      project.add_master(user)
    end

    context 'when the user has access to issues and merge requests' do
      let!(:merge_request) { create(:merge_request, source_project: project) }

      it 'contains the needed key value pairs' do
        expect(subject).to include(:coverage, :erased_at, :duration)
        expect(subject).to include(:artifacts, :runner, :pipeline)
        expect(subject).to include(:raw_path, :merge_request_path, :new_issue_path)
      end
    end

    context 'when the user can only read the build' do
      it "won't display the paths to issues and merge requests" do
        expect(subject['new_issue_path']).to be_nil
        expect(subject['merge_request_path']).to be_nil
      end
    end
  end
end
