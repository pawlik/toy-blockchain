# frozen_string_literal: true

require 'json'
require 'openssl'
require 'base64'

# Transaction representation. It can only validate that it is signed by the 
# private counterpart of the `from` key.
class Transaction
  attr_reader :amount
  attr_reader :to
  attr_reader :from

  def initialize(hash)
    @from = hash.fetch(:from)
    @to = hash.fetch(:to)
    @amount = hash.fetch(:amount)
    @payload = hash.fetch(:payload)
    @signature = hash.fetch(:signature)
  end 

  def self.from_hash(hash)
    new(hash)
  end

  def signed?
    rsa = OpenSSL::PKey::RSA.new(@from, '')
    rsa.verify_pss(
      'SHA256',
      Base64.decode64(@signature),
      dup.unsign!.to_json,
      salt_length: :auto,
      mgf1_hash: 'SHA256'
    )
  rescue OpenSSL::PKey::RSAError # wrong signatures cause `neither PUB nor PRIV key`
    false
  end

  def unsign!
    @signature = ''
    self
  end

  def to_h
    {
      from: @from,
      to: @to,
      amount: @amount,
      payload: @payload,
      signature: @signature
    }
  end

  def to_json
    to_h.to_json
  end
end
