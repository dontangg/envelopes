require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = login
  end

  test "should require a user to be logged in" do
    logout

    get :edit, id: @user.id
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "should get edit" do
    get :edit, id: @user.id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:bank_options)
  end

  test "should successfully update account" do
    put :update, {
      id: @user.id,
      user: {
        email: 'newemail@example.com',
        password: 'new password',
        bank_id: 'uccu',
        bank_username: 'new bank username',
        bank_password: 'new bank password',
      },
      question: {
        '0' => 'first question?',
        '1' => 'next question?'
      },
      answer: {
        '0' => 'first answer!',
        '1' => 'next answer!'
      }
    }

    user = User.find(@user.id)

    assert_equal 'newemail@example.com', user.email
    assert_equal 'uccu', user.bank_id

    secret_questions = {'first question?' => 'first answer!', 'next question?' => 'next answer!'}
    assert_equal secret_questions, user.bank_secret_questions

    assert_redirected_to controller: 'users', action: 'edit'
  end

  test "should fail while trying to update account" do
    put :update, {
      id: @user.id,
      user: {
        email: nil
      }
    }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:bank_options)
  end

end
