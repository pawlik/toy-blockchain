require 'openssl'
require 'base64'
require 'digest/sha1'
require 'json'
require 'pry'
require 'pry-doc'

# block structure would be:

block = {
  transactions: {
    '0' => { from: '', to: 'miner_key.pub', amount: 100 }, # miner's reward
    '1' => {
      from: 'sender_key.pub',
      to: 'receiver_key.pub',
      amount: 123,
      payload: '',
      signature: ''
    },
    # transactions have indexes from 1 to 10, block with more are invalid
    # to verify transaction, replace signature with empty string, and verify it's JSON representation?
  },
  transactions_hash: 'merkle_hash_of_transactions',
  timestamp: Time.now.utc.to_i,
  allowed_miners: [ # only in gensis block?
    { key: 'public_key', address: '0.0.0.0:12345' },
    { key: 'other_public_key', address: '0.0.0.0:12346' }
  ],
  signature: 'XXX' # to verify block, replace signature with empty string, and verify signature
}

string = data.to_json

foo = OpenSSL::PKey::RSA.new(File.read('id_rsa_1'), '')
binding.pry

signed = foo.sign_pss('SHA256', string, salt_length: :max, mgf1_hash: 'SHA256')

puts signed

correct = foo.public_key.verify_pss('SHA256', signed, string, salt_length: :auto, mgf1_hash: 'SHA256')

puts correct.inspect

binding.pry
