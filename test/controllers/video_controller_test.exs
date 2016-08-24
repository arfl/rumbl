defmodule Rumbl.VideoControllerTest do
  use Rumbl.ConnCase

  alias Rumbl.Video

  setup %{conn: conn} = config do
    if username = config[:login_as] do
       user = insert_user(username: username)
       conn = assign(build_conn(), :current_user, user)
       {:ok, conn: conn, user: user}
     else
       :ok
    end
  end

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, video_path(conn, :new)),
      get(conn, video_path(conn, :index)),
      get(conn, video_path(conn, :show, 123)),
      get(conn, video_path(conn, :edit, 123)),
      put(conn, video_path(conn, :update, 123)),
      post(conn, video_path(conn, :create, %{})),
      delete(conn, video_path(conn, :delete, 123)),
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end

  @valid_attrs %{description: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{description: "", title: "", url: ""}

  @tag login_as: "max"
  test "lists all entries on index", %{conn: conn, user: user} do
    conn = get conn, video_path(conn, :index), user
    assert html_response(conn, 200) =~ "Listing videos"
  end

  @tag login_as: "max"
  test "renders form for new resources", %{conn: conn} do
    conn = get conn, video_path(conn, :new)
    assert html_response(conn, 200) =~ "New video"
  end

  @tag login_as: "max"
  test "creates resource and redirects when data is valid", %{conn: conn, user: user} do
    conn = post conn, video_path(conn, :create), video: @valid_attrs
    assert redirected_to(conn) == video_path(conn, :index)
    video = Repo.get_by(Video, @valid_attrs)
    assert video
    assert video.user_id == user.id
  end

  @tag login_as: "max"
  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    count_before = video_count(Video)
    conn = post conn, video_path(conn, :create), video: @invalid_attrs
    assert html_response(conn, 200) =~ "New video"
    assert video_count(Video) == count_before
  end

  @tag login_as: "max"
  test "shows chosen resource", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)
    conn = get conn, video_path(conn, :show, video)
    assert html_response(conn, 200) =~ "Show video"
  end

  @tag login_as: "max"
  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, video_path(conn, :show, -1)
    end
  end

  @tag login_as: "max"
  test "renders form for editing chosen resource", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)
    conn = get conn, video_path(conn, :edit, video)
    assert html_response(conn, 200) =~ "Edit video"
  end

  @tag login_as: "max"
  test "updates chosen resource and redirects when data is valid", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)
    conn = put conn, video_path(conn, :update, video), video: @valid_attrs
    assert redirected_to(conn) == video_path(conn, :show, video)
    assert Repo.get_by(Video, @valid_attrs)
  end

  @tag login_as: "max"
  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)
    conn = put conn, video_path(conn, :update, video), video: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit video"
  end

  @tag login_as: "max"
  test "deletes chosen resource", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)
    conn = delete conn, video_path(conn, :delete, video)
    assert redirected_to(conn) == video_path(conn, :index)
    refute Repo.get(Video, video.id)
  end

  @tag login_as: "max"
  test "authorizes actions agains access by other users", %{user: owner, conn: conn} do
    video = insert_video(owner, @valid_attrs)
    non_owner = insert_user(username: "cheater")
    conn = assign(conn, :current_user, non_owner)

    assert_error_sent :not_found, fn ->
      get(conn, video_path(conn, :show, video))
    end
    assert_error_sent :not_found, fn ->
      get(conn, video_path(conn, :edit, video))
    end
    assert_error_sent :not_found, fn ->
      put(conn, video_path(conn, :update, video), video: @valid_attrs)
    end
    assert_error_sent :not_found, fn ->
      delete(conn, video_path(conn, :update, video))
    end
  end

  defp video_count(query), do: Repo.one(from v in query, select: count(v.id))
end
