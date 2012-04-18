class Ability
  include CanCan::Ability

  def initialize(user)
    # You can only mess with your own stuff
    can :manage, User, id: user.id
    can :manage, Envelope, user_id: user.id
    can :manage, Transaction do |transaction|
      transaction.envelope.user_id == user.id
    end
    can :manage, Rule, user_id: user.id

  end

end
