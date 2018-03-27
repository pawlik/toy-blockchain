require 'openssl'
#
class Miner
  KEY_BYTES = 2048

  def initialize(rsa)
    @rsa = rsa
  end

  def self.generate
    new OpenSSL::PKey::RSA.generate(KEY_BYTES)
  end

  def public_key
    @rsa.public_key
  end
end
