require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  test "owned_by scope should return envelopes owned by the user specified" do
    envelopes = Envelope.owned_by(1)
  
    envelopes.each do |envelope|
      assert_equal 1, envelope.user_id, "owned_by(1) should only return envelopes owned by user 1"
    end
  end

  test "income scope should return income envelopes" do
    envelope = Envelope.income.first
    
    assert_equal "Available Cash", envelope.name
    assert envelope.parent_envelope_id.nil?, "The income envelope should not have a parent envelope"
    assert envelope.income?
    assert !envelope.unassigned?
  end
  
  test "unassigned scope should return unassigned envelopes" do
    envelope = Envelope.unassigned.first
    
    assert "Unassigned", envelope.name
    assert envelope.parent_envelope_id.nil?, "The unassigned envelope should not have a parent envelope"
    assert !envelope.income?
    assert envelope.unassigned?
  end
  
  test "generic scope should return generic envelopes" do
    envelopes = Envelope.generic
    
    envelopes.each do |envelope|
      assert !envelope.income?
      assert !envelope.unassigned?
    end
  end
  
  test "parent_envelope returns the parent envelope" do
    fuel_envelope = envelopes(:fuel)
    auto_envelope = envelopes(:auto)
    
    assert_equal auto_envelope, fuel_envelope.parent_envelope
  end

  test "child_envelopes returns the child envelopes" do
    fuel_envelope = envelopes(:fuel)
    auto_envelope = envelopes(:auto)

    assert auto_envelope.child_envelopes.include?(fuel_envelope)
  end
  
  test "to_param returns id-name.parameterize" do
    envelope = envelopes(:available_cash)
    
    assert_equal "#{envelope.id}-available-cash", envelope.to_param
  end
end
