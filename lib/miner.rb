# frozen_string_literal: true

require 'openssl'
require 'base64'

class Miner
  KEY_BYTES = 2048

  def initialize(rsa, identifier)
    @rsa = rsa
    @identifier = identifier
  end

  def self.generate(identifier)
    new OpenSSL::PKey::RSA.generate(KEY_BYTES), identifier
  end

  def public_key
    @rsa.public_key.to_s
  end

  def sign(block)
    block.signed_by = @identifier
    raise 'Invalid block' unless block.transactions_valid?
    block.unsign!

    block.sign!(sign_str(block.to_json))
    block
  end

  # If the block has been signed by this exact miner
  def signed_by_self?(block)
    block = block.dup
    signature = block.unsign!
    verify_str(signature, block.to_json)
  end

  private

  def sign_str(str)
    Base64.encode64(
      @rsa.sign_pss(
        'SHA256',
        str,
        salt_length: :max,
        mgf1_hash: 'SHA256'
      )
    )
  end

  def verify_str(signature, str)
    @rsa.verify_pss(
      'SHA256',
      Base64.decode64(signature),
      str,
      salt_length: :auto,
      mgf1_hash: 'SHA256'
    )
  end
end
