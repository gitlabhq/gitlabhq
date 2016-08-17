require 'spec_helper'

describe Gitlab::DataBuilder::Build do
  let(:build) { create(:ci_build) }

  describe '.build' do
    let(:data) do
      described_class.build(build)
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:ref]).to eq(build.ref) }
    it { expect(data[:sha]).to eq(build.sha) }
    it { expect(data[:tag]).to eq(build.tag) }
    it { expect(data[:build_id]).to eq(build.id) }
    it { expect(data[:build_status]).to eq(build.status) }
    it { expect(data[:build_allow_failure]).to eq(false) }
    it { expect(data[:project_id]).to eq(build.project.id) }
    it { expect(data[:project_name]).to eq(build.project.name_with_namespace) }
  end
end
