# frozen_string_literal: true

require './lib/miner.rb'

# Most blockchain validations are here.
# Chain knows the balances of each address and can detect overspending etc.
# First added block is a genesis block.
class Chain
  MINER_REWARD = 100
  MINING_TIME = 10 * 60 # 10 minutes

  def add(block)
    @the_chain ||= []
    raise 'Invalid block' unless block.signed?
    assert_signed_by_approved_miners(block)
    validate_transactions!(block)
    validate_previous_hash!(block)
    validate_height!(block)
    validate_timestamp!(block)
    update_balances!(block)
    @the_chain << block
    true
  end

  def size
    @the_chain.size
  end

  def balance(pkey)
    @balances[pkey]
  end

  def initialize
    @balances = {}
  end

  private

  def validate_timestamp!(block)
    return if @the_chain.empty?
    return if (block.transactions || []).count do |index, transaction|
      !miner_reward?(transaction, index)
    end >= 10
    raise 'Invalid block (mined too soon)' unless 
      @the_chain.last.timestamp + MINING_TIME <= block.timestamp
  end

  def validate_previous_hash!(block)
    if @the_chain.count.zero?
      return if block.previous_hash.empty?
      raise 'Invalid block (genesis block\'s previous hash is not empty)' 
    end
    raise 'Invalid block (previous hash does not match)' unless block.previous_hash == @the_chain.last&.signature
  end

  def validate_height!(block)
    expected_height = (@the_chain.last&.height || -1) + 1
    raise 'Invalid block (height mismatch)' if expected_height != block.height
  end

  def update_balances!(block)
    block.transactions.each do |index, transaction|
      assert_no_overspending!(transaction) unless miner_reward?(transaction, index)
      @balances[transaction.to] = (@balances[transaction.to] || 0.0) + transaction.amount
      @balances[transaction.from] -= transaction.amount unless miner_reward?(transaction, index)
    end
  end

  def miner_reward?(transaction, index)
    transaction.from == '' && index == '0'
  end

  def assert_no_overspending!(transaction)
    balance_from = @balances[transaction.from] || 0
    raise 'Overspending!' if balance_from < transaction.amount
  end

  def validate_transactions!(block)
    block.transactions.each do |index, transaction|
      raise 'Invalid block (wrong miner\'s reward)' if index == '0' && transaction.amount != MINER_REWARD
    end
  end

  def assert_signed_by_approved_miners(block)
    genesis_block = @the_chain.first || block
    pkey = OpenSSL::PKey::RSA.new(genesis_block.allowed_miners[block.signed_by][:key])
    miner = Miner.new(pkey, block.signed_by)
    raise 'Invalid block (miner\'s key not found on the list)' unless miner.signed_by_self?(block)
  end
end
