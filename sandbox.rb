require 'openssl'
require 'base64'
require 'digest/sha1'
require 'json'
require 'pry'
require 'pry-doc'
require 'pp'

miner_1_pub_key = "-----BEGIN PUBLIC KEY-----\n" +
"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA28H+iFAf+G4JZVD1x+lI\n" +
"em4CkhNWw/K6TSdz9N6fc0uvus/Nwh+rSLe+PAhXiiEvAqWbhiv1TT7fGuocVHBI\n" +
"yg9AsemnUzs8sdntyY4vt9r9rNMUUJaUH6rIHpA/lff6f4tBq92hx10R3ArX1wH1\n" +
"vIsK8J76PmZSnfQPiVxRECRXcBqSdDq+Mg4zTY2A/j0+FxpxbN4ZkwcUxXaPEEZl\n" +
"jAbBsmn/fX+2dqYUedrEHIvy9Xyv2C1jQWjUmhB8RL1c7cKF6t+6zx9F3TstsFh+\n" +
"/aZ5X4bmTPjNrmH9rFDfBMGuhIpVo/CU40XcpNr8443HlLLd8DQKiDJW/WgS+a3s\n" +
"zQIDAQAB\n" +
"-----END PUBLIC KEY-----\n"

miner_2_pub_key = "-----BEGIN PUBLIC KEY-----\n" +
"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAynBKzo7ryh/ZmKLOZINK\n" +
"NQzM+MzLi+k95/VoKRNQyoDExlExDaHXgo9Cw7HaUhwZqBIWq9eevcngXacfiMZY\n" +
"G6fzn+QbYt3LW7HoVZVl8vRna+n9PWIMb2EcWEmr0ce822cIS+UfdwrZHJf8o0h5\n" +
"qBkMsF5DUPW410mq1VjJnxX7B+EoCGdGPiMf2D/Txb8eqXmsfejxDPBU5Z4jApEc\n" +
"FHmYPeZpy+8TwWaBhTN4JRGTvKtqbD3rafweMfHALB6HXnhrlFHktaZ2hReA1S2s\n" +
"zR7y/iOYzfFzPz2T2xoqkq323AJdd4zZRZqT1NMslk0+V7nOW8U/PM9UseZ+Sty4\n" +
"cwIDAQAB\n" +
"-----END PUBLIC KEY-----\n"


# block structure would be:

block = {
  transactions: {
    '0' => { from: '', to: miner_1_pub_key, amount: 100 }, # miner's reward
    # transactions have indexes from 1 to 10, block with more are invalid
    # to verify transaction, replace signature with empty string, and verify it's JSON representation?
  },
  transactions_hash: 'merkle_hash_of_transactions',
  timestamp: Time.now.utc.to_i,
  allowed_miners: { # only in gensis block, this entry should not exist for other blocks
    'miner_1' => { key: miner_1_pub_key, address: '0.0.0.0:10800' },
    'miner_2' => { key: miner_2_pub_key, address: '0.0.0.0:10801' }
  },
  signed_by: 'miner_1',
  signature: ''
  # to verify block, replace signature with empty string, and verify signature
}

def double_sha2(sth)
  Digest::SHA2.hexdigest(
    Digest::SHA2.hexdigest(sth)
  )
end

def merkle(transactions) # actually transaction hashes already
  return double_sha2(transactions.first + transactions.first) if transactions.count == 1
  return double_sha2(transactions.join) if transactions.count == 2

  new_arr = []
  transactions.each_slice(2) do |x, y|
    new_arr << merkle([x, y || x])
  end

  merkle(new_arr)
end

def prepare_transactions_hash(hash)
  transactions_array = hash.values.map(&:to_json).map { |str| double_sha2(str) }
end

block[:transactions_hash] = merkle(prepare_transactions_hash(block[:transactions]))

block_string = block.to_json

private_rsa = OpenSSL::PKey::RSA.new(File.read('keys/miner_1'), '')

block[:signature] = Base64.encode64(
  private_rsa.sign_pss('SHA256', block_string, salt_length: :max, mgf1_hash: 'SHA256')
)

signed_block_string = block.to_json

pp signed_block_string

block_from_string = JSON.parse(signed_block_string, symbolize_names: true)

signature = Base64.decode64(block_from_string[:signature])

block_from_string[:signature] = ''

unsigned_block_string = block_from_string.to_json

miner_pub_key = OpenSSL::PKey::RSA.new(miner_1_pub_key, '')

verified = miner_pub_key.verify_pss(
  'SHA256', 
  signature, 
  unsigned_block_string, 
  salt_length: :auto,
  mgf1_hash: 'SHA256'
)

pp verified
# correct = foo.public_key.verify_pss('SHA256', signed, string, salt_length: :auto, mgf1_hash: 'SHA256')

# puts correct.inspect
