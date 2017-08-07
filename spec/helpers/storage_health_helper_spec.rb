require 'spec_helper'

describe StorageHealthHelper do
  describe '#failing_storage_health_message' do
    let(:health) do
      Gitlab::Git::Storage::Health.new(
        "<script>alert('storage name');)</script>",
        []
      )
    end

    it 'escapes storage names' do
      escaped_storage_name = '&lt;script&gt;alert(&#39;storage name&#39;);)&lt;/script&gt;'

      result = helper.failing_storage_health_message(health)

      expect(result).to include(escaped_storage_name)
    end
  end
end
