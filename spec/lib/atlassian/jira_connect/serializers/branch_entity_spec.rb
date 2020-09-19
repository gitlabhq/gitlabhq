# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::BranchEntity do
  let(:project) { create(:project, :repository) }
  let(:branch) { project.repository.find_branch('improve/awesome') }

  subject { described_class.represent(branch, project: project).as_json }

  it 'sets the hash of the branch name as the id' do
    expect(subject[:id]).to eq('bbfba9b197ace5da93d03382a7ce50081ae89d99faac1f2326566941288871ce')
  end
end
