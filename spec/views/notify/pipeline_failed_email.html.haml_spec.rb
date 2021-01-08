# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/pipeline_failed_email.html.haml' do
  it_behaves_like 'pipeline status changes email' do
    let(:title) { "Pipeline ##{pipeline.id} has failed!" }
    let(:status) { :failed }
  end
end
