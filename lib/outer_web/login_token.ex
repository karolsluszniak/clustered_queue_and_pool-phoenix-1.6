defmodule OuterWeb.LoginToken do
  alias OuterWeb.Endpoint
  alias Phoenix.Token

  @salt "6BGawhsA"
  @max_age 60

  def sign(user_id) do
    Token.sign(Endpoint, @salt, user_id)
  end

  def verify(token) do
    Token.verify(Endpoint, @salt, token, max_age: @max_age)
  end
end
