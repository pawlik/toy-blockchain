require './lib/transactions_hash.rb'

RSpec.describe TransactionsHash do
  def sha(str)
    Digest::SHA2.hexdigest(str)
  end

  describe '.calculate' do
    subject { TransactionsHash.new(array_of_strings).calculate }

    context 'when one item' do
      let(:array_of_strings) { %w[foo] }

      specify 'it is the item hashed twice' do
        expect(subject).to eq sha(sha('foo'))
      end
    end

    context 'when more items' do
      let(:array_of_strings) { %w[foo bar baz] }

      specify 'it is a hash of concatenation of hashes' do
        expect(subject).to eq sha(sha('foo') + sha('bar') + sha('baz'))
      end
    end
  end
end
