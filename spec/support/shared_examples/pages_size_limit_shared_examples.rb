# frozen_string_literal: true

shared_examples 'pages size limit is' do |size_limit|
  context "when size is below the limit" do
    before do
      allow(metadata).to receive(:total_size).and_return(size_limit - 1.megabyte)
    end

    it 'updates pages correctly' do
      subject.execute

      expect(deploy_status.description).not_to be_present
      expect(project.pages_metadatum).to be_deployed
    end
  end

  context "when size is above the limit" do
    before do
      allow(metadata).to receive(:total_size).and_return(size_limit + 1.megabyte)
    end

    it 'limits the maximum size of gitlab pages' do
      subject.execute

      expect(deploy_status.description)
        .to match(/artifacts for pages are too large/)
      expect(deploy_status).to be_script_failure
    end
  end
end
