class UsersController < ApplicationController
  def edit
    @user = params[:id] == current_user_id ? current_user : User.find(params[:id])
    authorize! :update, @user

    @bank_options = Syrup.institutions.map {|institution| [institution.name, institution.id] }
    @bank_options[0, 0] = [["None", ""]]
  end

  def update
    @user = params[:id] == current_user_id ? current_user : User.find(params[:id])
    authorize! :update, @user

    if params[:question]
      @user.bank_secret_questions = {}
      params[:question].each do |index, question|
        @user.bank_secret_questions[question] = params[:answer][index]
      end
    else
      @user.bank_secret_questions = nil
    end

    if @user.update_attributes(user_params)
      redirect_to edit_user_url(@user), notice: 'Your account was successfully updated.'
    else
      @bank_options = Syrup.institutions.map {|institution| [institution.name, institution.id] }
      @bank_options[0, 0] = [["None", ""]]

      render action: "edit"
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :bank_id, :bank_username, :bank_password, :bank_secret_questions, :bank_account_id)
  end

end
