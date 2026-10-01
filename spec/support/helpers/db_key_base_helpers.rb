# frozen_string_literal: true

module DbKeyBaseHelpers
  # The last key is the current one, as in `db_key_base` configuration.
  def stub_db_key_base_keys(*keys)
    allow(Settings).to receive(:db_key_base_keys).and_return(keys)
    # KeyProvider memoizes providers built from the previous keys
    allow(Gitlab::Encryption::KeyProvider.instance).to receive(:providers).and_return({})
  end
end
