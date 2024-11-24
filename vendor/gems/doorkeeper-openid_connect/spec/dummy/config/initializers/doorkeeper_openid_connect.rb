# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer 'dummy'

  signing_key <<~EOL
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpgIBAAKCAQEAsjdnSA6UWUQQHf6BLIkIEUhMRNBJC1NN/pFt1EJmEiI88GS0
    ceROO5B5Ooo9Y3QOWJ/n+u1uwTHBz0HCTN4wgArWd1TcqB5GQzQRP4eYnWyPfi4C
    feqAHzQp+v4VwbcK0LW4FqtW5D0dtrFtI281FDxLhARzkhU2y7fuYhL8fVw5rUhE
    8uwvHRZ5CEZyxf7BSHxIvOZAAymhuzNLATt2DGkDInU1BmF75tEtBJAVLzWG/j4L
    PZh1EpSdfezqaXQlcy9PJi916UzTl0P7Yy+ulOdUsMlB6yo8qKTY1+AbZ5jzneHb
    GDU/O8QjYvii1WDmJ60t0jXicmOkGrOhruOptwIDAQABAoIBAQChYNwMeu9IugJi
    NsEf4+JDTBWMRpOuRrwcpfIvQAUPrKNEB90COPvCoju0j9OxCDmpdPtq1K/zD6xx
    khlw485FVAsKufSp4+g6GJ75yT6gZtq1JtKo1L06BFFzb7uh069eeP7+wB6JxPHw
    KlAqwxvsfADhxeolQUKCTMb3Vjv/Aw2cO/nn6RAOeftw2aDmFy8Xl+oTUtSxyib0
    YCdU9cK8MxsxDdmowwHp04xRTm/wfG5hLEn7HMz1PP86iP9BiFsCqTId9dxEUTS1
    K+VAt9FbxRAq5JlBocxUMHNxLigb94Ca2FOMR7F6l/tronLfHD801YoObF0fN9qW
    Cgw4aTO5AoGBAOR79hiZVM7/l1cBid7hKSeMWKUZ/nrwJsVfNpu1H9xt9uDu+79U
    mcGfM7pm7L2qCNGg7eeWBHq2CVg/XQacRNtcTlomFrw4tDXUkFN1hE56t1iaTs9m
    dN9IDr6jFgf6UaoOxxoPT9Q1ZtO46l043Nzrkoz8cBEBaBY20bUDwCYjAoGBAMet
    tt1ImGF1cx153KbOfjl8v54VYUVkmRNZTa1E821nL/EMpoONSqJmRVsX7grLyPL1
    QyZe245NOvn63YM0ng0rn2osoKsMVJwYBEYjHL61iF6dPtW5p8FIs7auRnC3NrG0
    XxHATZ4xhHD0iIn14iXh0XIhUVk+nGktHU1gbmVdAoGBANniwKdqqS6RHKBTDkgm
    Dhnxw6MGa+CO3VpA1xGboxuRHeoY3KfzpIC5MhojBsZDvQ8zWUwMio7+w2CNZEfm
    g99wYiOjyPCLXocrAssj+Rzh97AdzuQHf5Jh4/W2Dk9jTbdPSl02ltj2Z+2lnJFz
    pWNjnqimHrSI09rDQi5NulJjAoGBAImquujVpDmNQFCSNA7NTzlTSMk09FtjgCZW
    67cKUsqa2fLXRfZs84gD+s1TMks/NMxNTH6n57e0h3TSAOb04AM0kDQjkKJdXfhA
    lrHEg4z4m4yf3TJ9Tat09HJ+tRIBPzRFp0YVz23Btg4qifiUDdcQWdbWIb/l6vCY
    qhsu4O4BAoGBANbceYSDYRdT7a5QjJGibkC90Z3vFe4rDTBgZWg7xG0cpSU4JNg7
    SFR3PjWQyCg7aGGXiooCM38YQruACTj0IFub24MFRA4ZTXvrACvpsVokJlQiG0Z4
    tuQKYki41JvYqPobcq/rLE/AM7PKJftW35nqFuj0MrsUwPacaVwKBf5J
    -----END RSA PRIVATE KEY-----
  EOL

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    resource_owner.current_sign_in_at
  end

  reauthenticate_resource_owner do |_resource_owner, _return_to|
    redirect_to '/reauthenticate'
  end

  select_account_for_resource_owner do |_resource_owner, _return_to|
    redirect_to '/select_account'
  end

  subject do |resource_owner|
    resource_owner.id
  end

  claims do
    claim :name do |user|
      user.name
    end

    claim :variable_name, scope: :openid do |user, scopes|
      scopes.exists?(:profile) ? 'profile-name' : 'openid-name'
    end

    claim :created_at, scope: :openid do |user|
      user.created_at.to_i
    end

    claim :updated_at do |user|
      user.updated_at.to_i
    end

    claim :token_id, scope: :openid do |user, scopes, token|
      token.id
    end

    claim(:both_responses, scope: :openid, response: [:id_token, :user_info]) { 'both' }
    claim(:id_token_response, scope: :openid, response: [:id_token]) { 'id_token' }
    claim(:user_info_response, scope: :openid, response: :user_info) { 'user_info' }
  end
end
