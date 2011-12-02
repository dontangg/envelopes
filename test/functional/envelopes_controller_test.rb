require 'test_helper'

class EnvelopesControllerTest < ActionController::TestCase
  setup do
    login_as :jim
    @envelope = envelopes(:available_cash)
  end

  test "should require a user to be logged in" do
    logout

    get :index
    assert_redirected_to controller: 'sessions', action: 'new'

    get :show, id: @envelope.to_param
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:parent_envelopes)
    assert_not_nil assigns(:child_envelopes)

    assert_select 'section#dashboard' do
      tags = css_select('.name').map {|tag| tag.to_s}.join
      Envelope.owned_by(session[:user_id]).each do |envelope|
        assert tags.include?(envelope.name), "The envelope named \"#{envelope.name}\" is missing"
      end
    end
  end

  test "should get show" do
    get :show, id: @envelope.to_param
    assert_response :success
  end

end
