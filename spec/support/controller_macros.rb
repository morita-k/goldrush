module ControllerMacros
  def login_user
    login_user1 = FactoryGirl.create(:User)

    before :each do
      controller.stub(:authenticate_user!).and_return true
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in login_user1
    end
  end
end
