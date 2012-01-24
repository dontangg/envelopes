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
    assert_not_nil assigns(:organized_envelopes)

    assert_select 'section#dashboard' do
      tags = css_select('.name').map {|tag| tag.to_s}.join
      Envelope.owned_by(session[:user_id]).each do |envelope|
        assert tags.include?(ERB::Util.html_escape(envelope.name)), "The envelope named \"#{envelope.name}\" is missing"
      end
    end
  end

  test "should show an envelope" do
    get :show, id: @envelope.to_param
    assert_response :success

    assert_not_nil assigns(:all_envelopes)
    assert_not_nil assigns(:organized_envelopes)
    assert_not_nil assigns(:envelope)
    assert_not_nil assigns(:envelope_options_for_select)
    assert_equal Date.today - 1.month, assigns(:start_date)
    assert_equal Date.today, assigns(:end_date)
    assert_not_nil assigns(:show_transfers)
    assert_not_nil assigns(:transactions)
  end

  test "should show envelopes to fill" do
    get :fill
    assert_response :success

    assert_not_nil assigns(:organized_envelopes)
    assert_not_nil assigns(:available_cash_envelope)
  end

  test "should fill the envelopes with money" do
    post :perform_fill
    assert_response :success
  end

end
