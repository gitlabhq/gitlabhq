# frozen_string_literal: true

require 'spec_helper'

describe './config/initializers/google_api_client.rb' do
  subject { Google::Apis::ContainerV1beta1 }

  it 'is needed' do |example|
    is_expected.not_to be_const_defined(:CloudRunConfig),
      <<-MSG.strip_heredoc
        The google-api-client gem has been upgraded!
        Remove:
          #{example.example_group.description}
          #{example.file_path}
      MSG
  end
end
