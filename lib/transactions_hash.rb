require 'digest/sha1'

# Trivial array hashing, not a Merkle tree at all
# hash each item, then concatenate the hashes and hash those for the result
class TransactionsHash
  def initialize(array)
    @the_array = array
  end

  def calculate
    sha2(@the_array.map { |item| sha2(item) }.join)
  end

  def sha2(str)
    Digest::SHA2.hexdigest(str)
  end
end
