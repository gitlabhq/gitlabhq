require 'spec_helper'

describe PathLock, models: true do
  let(:path_lock) { create(:path_lock) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:path) }
  it { is_expected.to validate_uniqueness_of(:path).scoped_to(:project_id, :user_id) }
end
