require 'spec_helper'

describe Gitlab::FileFinder do
  describe '#find' do
    let(:project) { create(:project, :public, :repository) }

    it_behaves_like 'file finder' do
      subject { described_class.new(project, project.default_branch) }
      let(:expected_file_by_name) { 'files/images/wm.svg' }
      let(:expected_file_by_content) { 'CHANGELOG' }
    end
  end
end
