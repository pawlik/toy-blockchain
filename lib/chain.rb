# frozen_string_literal: true

require './lib/miner.rb'

class Chain
  MINER_REWARD = 100

  def add(block)
    @the_chain ||= []
    raise 'Invalid block' unless block.signed?
    assert_signed_by_approved_miners(block)
    validate_transactions!(block)
    @the_chain << block
    true
  end

  def size
    @the_chain.size
  end

  private

  def validate_transactions!(block)
    block.transactions.each do |_index, transaction|
      raise 'Invalid block' if transaction.amount != MINER_REWARD
    end
  end

  def assert_signed_by_approved_miners(block)
    genesis_block = @the_chain.first || block
    pkey = OpenSSL::PKey::RSA.new(genesis_block.allowed_miners[block.signed_by][:key])
    miner = Miner.new(pkey)
    raise 'Invalid block (miner\'s key not found on the list)' unless miner.signed_by_self?(block)
  end
end
