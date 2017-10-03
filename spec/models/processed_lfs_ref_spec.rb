require 'spec_helper'

describe ProcessedLfsRef do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to have_db_column(:newrev).of_type(:string).with_options(null: false) }
  it { is_expected.to have_db_column(:ref).of_type(:string).with_options(null: false) }
end
