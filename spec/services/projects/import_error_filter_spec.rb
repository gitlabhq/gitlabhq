# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportErrorFilter, feature_category: :importers do
  it 'filters any full paths' do
    message = 'Error importing into /my/folder Permission denied @ unlink_internal - /var/opt/gitlab/gitlab-rails/shared/a/b/c/uploads/file'

    expect(described_class.filter_message(message)).to eq('Error importing into [FILTERED] Permission denied @ unlink_internal - [FILTERED]')
  end

  it 'filters any relative paths ignoring single slash ones' do
    message = 'Error importing into my/project Permission denied @ unlink_internal - ../file/ and folder/../file'

    expect(described_class.filter_message(message)).to eq('Error importing into [FILTERED] Permission denied @ unlink_internal - [FILTERED] and [FILTERED]')
  end
end
