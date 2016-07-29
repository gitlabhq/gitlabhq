require 'spec_helper'

describe "Indexer" do
  it "runs commands" do
    stub_application_setting(es_host: ['elastic-host1', 'elastic-host2'])
    expect(Gitlab::Popen).to receive(:popen).with(
      [File.join(Rails.root, 'bin/elastic_repo_indexer'), '1', 'full_repo_path'],
      nil,
      hash_including(
        'ELASTIC_CONNECTION_INFO' => {
                                       host: ApplicationSetting.current.elasticsearch_host,
                                       port: ApplicationSetting.current.elasticsearch_port
                                     }.to_json,
        'RAILS_ENV'               => Rails.env,
        'FROM_SHA' => '000000',
        'TO_SHA' => '1d1f2d'
      )
    ).and_return([[''], 0])

    Gitlab::Elastic::Indexer.new.run(1, 'full_repo_path', '000000', '1d1f2d')
  end
end
