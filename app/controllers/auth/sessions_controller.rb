
class Auth::SessionsController < Devise::SessionsController
  def new
    self.resource = resource_class.new(sign_in_params)
    self.resource.remember_me = 1
    clean_up_passwords(resource)
    respond_with(resource, serialize_options(resource))
  end
end

