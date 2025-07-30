defmodule Enkiro.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Enkiro.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_gamer_tag, do: "gamer#{System.unique_integer()}"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      gamer_tag: unique_gamer_tag()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Enkiro.Accounts.register_user()

    user
  end

  def role_fixture(attrs \\ %{}) do
    {:ok, role} =
      attrs
      |> Enum.into(%{name: "default_role", api_name: "default_api_role"})
      |> Enkiro.Accounts.create_role()

    role
  end

  def user_role_fixture(user, role) do
    %Enkiro.Accounts.UserRole{}
    |> Enkiro.Accounts.UserRole.changeset(%{user_id: user.id, role_id: role.id})
    |> Enkiro.Repo.insert!()
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def user_follow_fixture(attrs \\ %{}) do
    {:ok, follow} = Enkiro.Accounts.create_user_follow(attrs)

    follow
  end
end
