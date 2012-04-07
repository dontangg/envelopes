require 'test_helper'

class TransactionImporterTest < ActiveSupport::TestCase
  test "shouldn't import a transaction when unique_id isn't unique" do
    txn1 = FactoryGirl.create :transaction, unique_id: 'uniqueness'
    txn2 = FactoryGirl.build :transaction, unique_id: 'uniqueness', envelope: txn1.envelope

    assert_nil TransactionImporter.import(txn2)
  end

  test "import sets the original payee" do
    txn = FactoryGirl.build :transaction, payee: 'MY ORIGINAL'

    TransactionImporter.import(txn)

    assert_equal 'MY ORIGINAL', txn.original_payee
  end

  test "should only run the first matching rule" do
    txn = FactoryGirl.build :transaction, payee: 'MY ORIGINAL', envelope: nil
    envelope1 = FactoryGirl.create :envelope
    envelope2 = FactoryGirl.create :envelope
    rule1 = FactoryGirl.build :rule, search_text: 'ORIGINAL', replacement_text: 'ORIGIN', envelope_id: envelope1.id
    rule2 = FactoryGirl.build :rule, search_text: 'ORIGIN', replacement_text: 'ORIG', envelope_id: envelope2.id

    TransactionImporter.import(txn, [rule1, rule2])

    assert_equal 'ORIGIN', txn.payee
    assert_equal envelope1.id, txn.envelope_id
  end

  test "should clean the payee when no rules were run" do
    txn = FactoryGirl.build :transaction, payee: "P.O.S. PURCHASE COSTCO WHS 648 EAST 80 OREM UT"
    TransactionImporter.import(txn)
    assert_equal "Costco Whs 648 East 80 Orem Ut", txn.payee

    txn = FactoryGirl.build :transaction, payee: "2469216FE00SZ72QG APL*APPLE ITUNES STORE 866-712-7753 CA"
    TransactionImporter.import(txn)
    assert_equal "Apl*Apple Itunes Store Ca", txn.payee

    txn = FactoryGirl.build :transaction, payee: "COMCAST C849544000COMCAST WEB4820310261 WILSON,ROBERT REF # 012093005015459"
    TransactionImporter.import(txn)
    assert_equal "Comcast Web Wilson,Robert", txn.payee

    txn = FactoryGirl.build :transaction, payee: "2476501FA09A1ADHT FITNESS CENTER #1 OREM UT"
    TransactionImporter.import(txn)
    assert_equal "Fitness Center Orem Ut", txn.payee
  end
end
