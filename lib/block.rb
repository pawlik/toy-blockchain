# frozen_string_literal: true

require 'json'
require_relative 'transactions_hash.rb'
# TODO: add some desc later
# Block class
class Block
  def signed?
    !(@signature.nil? || @signature.empty?)
  end

  def sign!(signature)
    @signature = signature
  end

  def initialize(hash = {})
    @signature = hash.fetch(:signature)
    @transactions = hash.fetch(:transactions)
    @transactions_hash = hash.fetch(:transactions_hash)
    @timestamp = hash.fetch(:timestamp)
    @allowed_miners = hash.fetch(:allowed_miners)
    @height = hash.fetch(:height)
    @previous_hash = hash.fetch(:previous_hash)
    @signed_by = hash.fetch(:signed_by)
    @signature = hash.fetch(:signature)
  end

  def self.from_hash(hash)
    new(hash)
  end

  # The real implementation
  # would need canonical block as string representation
  # right now we assume that to_json does not change the order of stuff
  def to_json
    {
      transactions: @transactions,
      transactions_hash: @transactions_hash,
      timestamp: @timestamp,
      allowed_miners: @allowed_miners,
      height: @height,
      previous_hash: @previous_hash,
      signed_by: @signed_by,
      signature: @signature
    }.to_json
  end

  def transactions_valid?
    @transactions_hash == TransactionsHash.new(@transactions.map(&:to_json)).calculate
  end
end
