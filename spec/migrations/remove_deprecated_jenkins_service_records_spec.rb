# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20200511130129_remove_deprecated_jenkins_service_records.rb')
require Rails.root.join('db', 'post_migrate', '20200511130130_ensure_deprecated_jenkins_service_records_removal.rb')

RSpec.shared_examples 'remove DeprecatedJenkinsService records' do
  let(:services) { table(:services) }

  before do
    services.create!(type: 'JenkinsDeprecatedService')
    services.create!(type: 'JenkinsService')
  end

  it 'deletes services when template and attached to a project' do
    expect { migrate! }
      .to change { services.where(type: 'JenkinsDeprecatedService').count }.from(1).to(0)
      .and not_change { services.where(type: 'JenkinsService').count }
  end
end

RSpec.describe RemoveDeprecatedJenkinsServiceRecords, :migration do
  it_behaves_like 'remove DeprecatedJenkinsService records'
end

RSpec.describe EnsureDeprecatedJenkinsServiceRecordsRemoval, :migration do
  it_behaves_like 'remove DeprecatedJenkinsService records'
end
