class Presenter
  extend Forwardable
  
  def initialize(params)
    params.each_pair do |attribute, value| 
      self.send :"#{attribute}=", value
    end if params.respond_to? :each_pair
  end
end
