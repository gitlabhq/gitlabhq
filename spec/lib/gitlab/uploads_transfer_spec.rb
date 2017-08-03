require 'spec_helper'

describe Gitlab::UploadsTransfer do
  it 'leaves avatar uploads where they are' do
    project_with_avatar = create(:project, :with_avatar)

    described_class.new.rename_namespace('project', 'project-renamed')

    expect(File.exist?(project_with_avatar.avatar.path)).to be_truthy
  end
end
