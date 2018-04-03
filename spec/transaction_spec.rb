# frozen_string_literal: true

require './lib/transaction.rb'

RSpec.describe Transaction do
  subject { described_class.from_hash(transaction_hash) }
  let(:transaction_hash) { { from: from, to: to, amount: amount, payload: payload, signature: signature } }
  let(:from) { '' }
  let(:to) { '' }
  let(:amount) { 0 }
  let(:payload) { '' }
  let(:signature) { '' }

  describe '#signed?' do
    it { expect(subject.signed?).to eq false }

    context 'when signed with gibberish' do
      let(:signature) { 'foo' }

      it { expect(subject.signed?).to eq false }
    end

    context 'when from is empty then no signature is needed'

    context 'when correctly signed' do
      let(:subject) { described_class.from_hash(transaction_hash.merge(signature: signature)) }
      let(:rsa) { OpenSSL::PKey::RSA.generate(2048) }
      let(:from) { rsa.public_key.to_s }
      let(:unsigned_transaction) { described_class.from_hash(transaction_hash) }
      let(:transaction_hash) { { from: from, to: to, amount: amount, payload: payload, signature: '' } }
      let(:signature) do
        Base64.encode64(
          rsa.sign_pss('SHA256', unsigned_transaction.to_json, salt_length: :max, mgf1_hash: 'SHA256')
        )
      end

      it { expect(subject.signed?).to eq true }
    end
  end

  describe '#to_json' do
    it { expect(subject.to_json).to eq '{"from":"","to":"","amount":0,"payload":"","signature":""}' }
  end
end
