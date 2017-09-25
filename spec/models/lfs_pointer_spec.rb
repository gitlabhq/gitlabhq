require 'spec_helper'

describe LfsPointer do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to have_db_column(:blob_oid).of_type(:string) }
  it { is_expected.to have_db_column(:lfs_oid).of_type(:string) }
end
