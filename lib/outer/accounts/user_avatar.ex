defmodule Outer.Accounts.UserAvatar do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original, :thumb]

  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format jpg", :jpg}
  end

  def filename(version, {file, _user}) do
    "#{Path.rootname(file.file_name)}-#{version}"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  def acl(:thumb, _), do: :public_read
end
